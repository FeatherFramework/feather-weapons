dofile('tests/native_davy_collection_spec.lua')
if NativeTestBinoculars then dofile('shared/native_binoculars_policy.lua') end
if NativeTestCamera then dofile('shared/native_camera_policy.lua') end
GetConvarInt=function(name) return (name=='feather_native_utility' or name=='feather_native_lasso_reinforced'
    or name=='feather_native_davy_lantern' or NativeTestBinoculars and name=='feather_native_binoculars'
    or NativeTestCamera and name=='feather_native_camera') and 1 or 0 end
Config.CharacterAmmoTransportEnabled=true
dofile('client/character_ammunition_native_owner.lua')
local U=WeaponNativeUtilityItem
local bound={characterId='john',sessionId='s',epoch='e'}
local entries={}
local definitions={'utility_lasso_reinforced','utility_davy_lantern'}
if NativeTestBinoculars then definitions[3]='utility_binoculars' end
if NativeTestCamera then definitions[4]='utility_camera' end
for n,definition in ipairs(definitions) do
    local def=WeaponDefinitionCatalog.weapons[definition]
    entries[n]={identity=bound,equipmentSlot=({'weapon_utility','weapon_utility_secondary','weapon_utility_tertiary','weapon_utility_quaternary'})[n],
        row={id=171+n,revision=0,itemName=def.itemName,metadata=assert(U.Build(def,{serialNumber='S'..n}))}}
end
for _,mode in ipairs({'success','second_factory','second_cleanup'}) do
    local create,track,utility
    local factories,removed=0,0
    local owner=assert(WeaponCharacterAmmoNativeOwner.New({
        context=function() return {ok=true,value={characterId='john',sessionId='s',ped=7}} end,
        ped=function() return 7 end,dual=function() return {} end,
        creation=function(_,_,_,cleanup) return {cleanupSetup=cleanup} end,
        bootstrap=function(c,t,_,_,_,u)
            create,track,utility=c,t,u
            return {Start=function() return true end,Status=function() return {runtime={phase='active'}} end}
        end,
        utility=function(_,identity,current,sealed,def)
            factories=factories+1
            assert(current(identity))
            if mode=='second_factory' and factories==#definitions then error('uncertain factory') end
            local phase='idle'
            return {Create=function() assert(current(identity)); phase='active'; return true end,
                Release=function()
                    if mode=='second_cleanup' and def.id==definitions[#definitions] then return nil end
                    phase='released'; removed=removed+1; return true
                end,Status=function() return {phase=phase} end}
        end,
    }))
    assert(owner.Start())
    local adapter=assert(create(7,bound)); track(adapter,{})
    local tools=assert(utility(7,bound,function() return true end,{id='native_utility_collection'}))
    local made=tools.Create({items=entries})
    assert(not adapter.cleanupSetup(),'parent held while any utility is unconfirmed')
    if mode=='second_factory' then assert(not made and not tools.Release() and not adapter.cleanupSetup())
    elseif mode=='second_cleanup' then assert(made and not tools.Release() and not adapter.cleanupSetup())
    else assert(made and tools.Release() and removed==#definitions and adapter.cleanupSetup()) end
end
print('Davy actual native parent PASS: both child factories tracked and uncertain second factory/cleanup retain parent')
