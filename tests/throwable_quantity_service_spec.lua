Config={NativeAlphaRuntime=true,CharacterAmmunitionEnabled=true,CharacterAmmoTransportEnabled=true,
 NativeAlphaLifecycleWearEnabled=true,NativeThrowableQuantityContract=1,AmmunitionPools={enabled=false},DevMode=false}
GetConvarInt=function(name) return name=='feather_throwable_quantities' and 1 or 0 end
for _,p in ipairs({'shared/constants.lua','shared/definitions/ammunition.lua','shared/definitions/weapons.lua',
 'shared/character_ammunition.lua','shared/character_ammunition_catalog.lua','shared/character_ammunition_policy.lua',
 'shared/native_throwable_policy.lua','shared/native_throwable_item.lua','shared/character_ammunition_item.lua',
 'shared/character_ammunition_materialization.lua','shared/character_ammunition_loadout_lease.lua','shared/character_ammunition_runtime.lua'}) do dofile(p) end
local function copy(v) if type(v)~='table' then return v end;local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r end
local registered={};local alive,current,bucket=true,true,0
GetGameTimer=function() return 100 end
GetPlayerPed=function(source) assert(source==1);return 7 end
GetEntityCoords=function(ped) assert(ped==7);return {x=1,y=2,z=3} end
GetPlayerRoutingBucket=function() return bucket end
GetInvokingResource=function() return 'feather-inventory' end
AddEventHandler=function() end
CoreAdapter={ResolveSession=function() return {ok=true,value={characterId='john',sessionId='s'}} end,IsSessionCurrent=function() return current end}
local registry=assert(WeaponCharacterAmmoPolicy.Build(WeaponDefinitionCatalog))
local db={revision=0,pools={}};for id in pairs(registry.limits) do db.pools[id]=0 end
local function quantity(context)
 return {contract=3,kind='throwable_quantity',characterId='john',identity={characterId='john',sessionId='s',epoch=context.epoch},revision=db.revision,pools=copy(db.pools)}
end
local counts={observe=0,pickup=0,transfer=0};local allow=true
local inventory={GetCharacterFirearmRuntimeSnapshot=function(_,context)
 return {ok=true,value={characterId='john',revision=db.revision,pools=copy(db.pools),equipment={},throwableEquipment=quantity(context)}}
end}
local function save(pools)
 db.revision=db.revision+1;db.pools=copy(pools)
 return {ok=true,value={characterId='john',revision=db.revision,pools=copy(db.pools)}}
end
inventory.MutateCharacterAmmunition=function(_,context,spec)
 assert(registered.ValidateCharacterAmmoRuntimeOperation(context,'transfer',spec))
 counts.transfer=counts.transfer+1;local pools=copy(db.pools);pools[spec.ammunitionId]=pools[spec.ammunitionId]+spec.amount;return save(pools)
end
inventory.ObserveCharacterAmmunition=function(_,context,spec)
 assert(registered.ValidateCharacterAmmoRuntimeOperation(context,'observe',spec))
 local forged=copy(spec);forged.quantityRecovery.position.x=100
 assert(not registered.ValidateCharacterAmmoRuntimeOperation(context,'observe',forged),'reserved server location immutable')
 assert(spec.quantityRecovery.bucket==0 and spec.quantityRecovery.position.x==1)
 counts.observe=counts.observe+1;return save(spec.pools)
end
inventory.ReconcileNativeThrowablePickup=function(_,context,spec)
 assert(registered.ValidateCharacterAmmoRuntimeOperation(context,'pickup',spec))
 assert(spec.nativePickupPlan.version==2 and spec.nativePickupPlan.location.bucket==0)
 counts.pickup=counts.pickup+1
 local accepted=copy(spec.pools);if not allow then accepted.ammo_tomahawk_regular=db.pools.ammo_tomahawk_regular end
 local recovered=accepted.ammo_tomahawk_regular-db.pools.ammo_tomahawk_regular
 local result=save(accepted);result.value.quantityDeclined=not allow;result.value.recovered=recovered;return result
end
exports=setmetatable({['feather-inventory']=inventory,['feather-medical']={ReadNativeWeaponCondition=function()
 return {ok=true,value={lifeState=alive and 'alive' or 'dead',revision=0}} end}},
 {__call=function(_,name,fn) registered[name]=fn end})
WeaponNativeThrowablePickupServer={Ready=function() error('quantity mode cannot publish a physical recovery challenge') end}
dofile('server/services/character_ammunition_runtime.lua')
local S=WeaponCharacterAmmoService
local start=S.OpenLoadout(1,WeaponDefinitionCatalog,registry.limits)
local opened=assert(start.value,start.error and start.error.code)
assert(opened.throwable.contract==3 and opened.throwable.units==nil and opened.throwable.equipment==nil)
assert(S.ConfirmRestore(1,opened.runtime).ok and not S.IsNativeItemBound(113) and S.ValidateLoadout(1).ok)
local live=assert(S.Transfer(1,opened.runtime,'ammo_tomahawk_regular',2,'paid-loose-ammo').value)
assert(live.phase=='restoring' and live.pools.ammo_tomahawk_regular==2 and S.ConfirmRestore(1,live).ok)
live.phase='active';local report=copy(live);report.pools.ammo_tomahawk_regular=1
live=assert(S.Observe(1,report).value)
assert(live.pools.ammo_tomahawk_regular==1 and counts.observe==1 and S.ValidateLoadout(1).ok)
report=copy(live);report.pools.ammo_tomahawk_regular=2
live=assert(S.NativePickup(1,report).value)
assert(live.phase=='active' and live.pools.ammo_tomahawk_regular==2 and counts.pickup==1 and S.ValidateLoadout(1).ok)
allow=false;report=copy(live);report.pools.ammo_tomahawk_regular=3
local refused=S.NativePickup(1,report)
assert(refused.ok and refused.quantityDeclined and refused.value.pools.ammo_tomahawk_regular==2
 and refused.value.revision==live.revision+1 and S.ValidateLoadout(1).ok,'definite no-credit response leaves session active')
live=refused.value;alive=false;report=copy(live);report.pools.ammo_tomahawk_regular=3
assert(not S.NativePickup(1,report).ok and counts.pickup==2,'dead player cannot dispatch quantity claim')
print('PASS actual quantity service: empty activation, ordinary funding, signed spend location, pickup/no-credit active ack, no physical item lease/challenge, current-life gates; modeled Inventory provider')
