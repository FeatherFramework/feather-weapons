local registered={};exports=function(name,fn) registered[name]=fn end
GetInvokingResource=function() return 'feather-shops' end
DefinitionRegistry={IsReady=function() return true end};IssuanceService={PurchaseAvailable=function() return true end}
vector3=function(x,y,z) return {x=x,y=y,z=z} end
dofile('config.lua');dofile('shop_config.lua')
-- Deployment preserves older operator configs that predate this field.
Config.NativeThrowablePickupPriorPolicy=nil
GetConvar=function(name,default) return name=='feather_throwable_quantities' and '1' or default end
GetConvarInt=function(name,default) return name=='feather_throwable_quantities' and 1 or default end
dofile('paid_throwable_test.lua')
assert(Config.NativeThrowablePickupPriorPolicy.w_melee_tomahawk01==true
 and Config.NativeThrowablePickupPriorPolicy.w_melee_tomahawk02==true)
for _,group in ipairs({'weapons','ammunition','attachments'}) do dofile('shared/definitions/'..group..'.lua') end
dofile('shared/native_melee_catalog.lua');dofile('shared/native_throwable_policy.lua')
dofile('paid_throwable_shop_test.lua');dofile('server/services/gun_store_catalog.lua')
assert(Config.NativeThrowableQuantityContract==1 and Config.NativeThrowableUnitsEnabled==false
 and Config.NativeThrowablePickupContract==0 and Config.NativeThrowableNativeCollectionContract==0)
assert(WeaponNativeThrowablePolicy.QuantityEnabled() and not WeaponNativeThrowablePolicy.UnitsEnabled())
local result=WeaponGunStore.Build(WeaponStoreConfig,WeaponDefinitionCatalog);assert(result.ok,result.message)
local generic,physical
for _,offer in ipairs(result.value.stores[1].offers) do
 if offer.itemName=='ammo_tomahawk_regular' then generic=offer end
 if offer.itemName=='weapon_thrown_tomahawk' then physical=offer end
end
assert(generic and generic.category=='ammunition' and generic.packSize==1 and generic.unitPrice==150 and not physical)
local f=assert(io.open('fxmanifest.lua'));local manifest=f:read('*a');f:close()
assert(manifest:find('/client/throwable_quantity_owner.lua',1,true)<manifest:find('/client/native_throwable_adapter.lua',1,true))
print('PASS quantity shop/bootstrap: explicit opt-in, legacy hosts disabled, existing ammo name/one-unit paid offer, no serialized weapon purchase, carrier manifest order')
