Config={DevMode=true,NativeAlphaRuntime=true,CharacterAmmunitionEnabled=true,CharacterAmmoTransportEnabled=true,
 NativeAlphaCharacterId='Jane',AmmunitionPools={enabled=false},Escrow={maxTotal=200},
 Issuance={trustedResources={['feather-weapons']=true},allowedPurposes={development_grant=true}}}
for _,p in ipairs({'shared/constants.lua','shared/definitions/ammunition.lua','shared/definitions/weapons.lua',
 'shared/validation.lua','shared/character_ammunition_item.lua'}) do dofile(p) end
local function clone(v) if type(v)~='table' then return v end; local t={}; for k,x in pairs(v) do t[k]=clone(x) end; return t end
WeaponResult={Ok=function(v) return {ok=true,value=v} end,Error=function(c,m,d) return {ok=false,error={code=c,message=m,details=d}} end}
WeaponErrors={ITEM_INVALID='invalid',AUTHORIZATION_INVALID='denied',OPERATION_CONFLICT='conflict'}
local enabled,stopping,current=1,false,true
GetConvarInt=function() return enabled end
GetGameTimer=function() return 100 end
GetResourceState=function() return 'stopped' end
GetPlayers=function() return {'1'} end
CoreAdapter={NormalizeCharacterId=function(v) return type(v)=='string' and v or nil end,
 ResolveSession=function() return {ok=true,value={characterId='Jane',sessionId='s'}} end,
 IsSessionCurrent=function() return current end}
WeaponCharacterAmmoDispatcher={Status=function() return {phase='active',identity={characterId='Jane',sessionId='s',epoch='e'}} end}
WeaponNativeEquipmentBindings={IsStopping=function() return stopping end}
WeaponCharacterAmmoInventoryProvider={Status=function() return 'ready' end}
WeaponCharacterAmmoPolicy={Build=function() return {weapons={revolver_cattleman={}}} end}
DefinitionRegistry={Get=function(_,id) return WeaponResult.Ok(WeaponDefinitionCatalog.weapons[id]) end,
 ValidateAttachmentSet=function() return WeaponResult.Ok(true) end}
dofile('server/services/metadata.lua')
local recorded,readFails=0,false
WeaponProvenanceService={IsReady=function() return true end,
 FindIssuanceEvent=function() if readFails then return WeaponResult.Error('unavailable','read failed') end
  return WeaponResult.Ok({eventId=recorded>0 and 1 or nil}) end,
 Record=function() recorded=recorded+1; return WeaponResult.Ok({eventId=1}) end}
local registered={}
local caller='feather-inventory'
GetInvokingResource=function() return caller end
local writes,receipt,lost=0,nil,false
json={encode=function(v)
 local parts={}; for _,x in ipairs(v) do parts[#parts+1]=tostring(x) end; return table.concat(parts,'|')
end}
exports=setmetatable({['feather-inventory']={GetNativeIssuanceContract=function() return {contractVersion=1,ready=true} end,
 IssueNativeFirearmOnce=function(_,ctx,spec)
 assert(registered.ValidateNativeIssuance(ctx,spec))
 local forged=clone(spec); forged.metadata.ammo.loaded=99
 assert(not registered.ValidateNativeIssuance(ctx,forged),'ticket binds exact immutable metadata')
 if receipt then
  if receipt.fingerprint~=spec.fingerprint then return WeaponResult.Error('conflict','payload changed') end
  local v=clone(receipt.value); v.replayed=true; return WeaponResult.Ok(v)
 end
 writes=writes+1
 local v={itemInstanceId=200,inventoryId=2,revision=0,characterId='Jane',definitionId=spec.definitionId,
  itemName=spec.itemName,serialNumber=spec.metadata.serialNumber,metadata=clone(spec.metadata)}
 assert(WeaponCharacterAmmoItem.Validate(v.metadata,WeaponDefinitionCatalog.weapons.revolver_cattleman))
 receipt={fingerprint=spec.fingerprint,value=v}
 if lost then error('reply lost after durable commit') end
 return WeaponResult.Ok(clone(v))
end}}, {__call=function(_,n,f) registered[n]=f end})
dofile('server/services/issuance.lua')
local function issue(overrides,resource)
 local req={characterId='Jane',definitionId='revolver_cattleman',purpose='development_grant',requestId='native-test-v1'}
 for k,v in pairs(overrides or {}) do req[k]=v end
 return IssuanceService.Issue({},req,resource or 'feather-weapons')
end
enabled=0; assert(not issue().ok and writes==0)
enabled=1; stopping=true; assert(not issue().ok and writes==0); stopping=false
current=false; assert(not issue().ok); current=true
assert(not issue(nil,'untrusted').ok)
assert(not issue({loadedAmmo=2}).ok and not issue({quality=90}).ok)
assert(not issue({provenance='malformed'}).ok)
lost=true; assert(not issue().ok and writes==1 and recorded==0)
lost=false; local result=issue(); assert(result.ok and result.value.replayed and writes==1 and recorded==1)
assert(result.value.metadata.ammo.ownership=='character' and result.value.metadata.ammo.loaded==nil)
assert(issue().ok and writes==1 and recorded==1)
readFails=true; assert(not issue().ok and writes==1 and recorded==1,'failed event lookup cannot invent a new issuance event')
readFails=false; assert(issue().ok and writes==1 and recorded==1)
assert(not issue({provenance={reference='changed'}}).ok and writes==1)
caller='untrusted'; assert(not registered.ValidateNativeIssuance({},{}))
print('Native issuance PASS (real metadata validation, gates, immutable ticket, lost-reply durable replay, provenance recovery, payload conflict; mocked Inventory)')
