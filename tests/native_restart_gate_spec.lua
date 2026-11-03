local f=assert(io.open('server/services/native_equipment_transition.lua','r'));local text=f:read('*a');f:close()
local body=assert(text:match('(function WeaponNativeEquipmentBindings.AcceptanceTransition.-)function WeaponNativeEquipmentBindings.AcceptanceStatus'))
local flags,dispatch,overlaps={},0,0
WeaponNativeEquipmentBindings={}
enabled=function() return true end
GetConvarInt=function(n,d) return flags[n] or d end
GetResourceState=function() return 'stopped' end
denied=function(code) return {ok=false,error={code=code}} end
identity=function(v) return type(v)=='table' end
copy=function(v) return v end
WeaponCharacterAmmoDispatcher={Status=function() return {phase='active',identity={}} end}
coordinator={Begin=function() dispatch=dispatch+1;return {ok=true} end}
WeaponNativeEquipmentTransition={ProbeOverlap=function() overlaps=overlaps+1;return {ok=true} end}
assert(load(body))()
assert(not WeaponNativeEquipmentBindings.AcceptanceTransition(1,false).ok and dispatch==0)
flags.feather_native_restart_suite=1
assert(WeaponNativeEquipmentBindings.AcceptanceTransition(1,false).ok and dispatch==1,'restart opt-in authorizes normal dry-run binding')
assert(not WeaponNativeEquipmentBindings.AcceptanceTransition(1,true).ok and overlaps==0,'restart gate does not authorize overlap probe')
flags.feather_native_acceptance_suite=1
assert(WeaponNativeEquipmentBindings.AcceptanceTransition(1,true).ok and overlaps==1)
print('Restart binding gate PASS: actual binding accepts restart dry-run, keeps overlap separately gated, default off')
