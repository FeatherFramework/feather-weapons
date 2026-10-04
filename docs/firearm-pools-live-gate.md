# Firearm ammunition pools: first live gate

Experimental; not general catalog acceptance. No SQL/seed changes required.
Set Config.AmmunitionPools.enabled = true on the development server; leave its
allowlist at revolver_cattleman only. Deploy the complete Weapons resource and
restart it. Keep offhand and other ammunition-using weapons unequipped for this
first test, so observations concern only the Cattleman. Do not expand the list yet.

1. Record Inventory ammo quantities and WeaponMetadataInspect 1 before enabling.
2. Preserve existing Express ownership; load 10 Regular through ammo management
   without unloading Express. Inventory must decrease by exactly 10 Regular.
3. Cycle Regular/Express in the wheel. Confirm both funded counts remain and
   other unfunded revolver types remain zero. Run weaponruntime.
4. Fire one Regular, switch to Express and fire one. Each corresponding pool
   must decrease once, and switching alone must not consume or create ammo.
5. Checkpoint, restart twice and reconnect. Confirm both pools and selected type.
6. Partially unload selected ammo, then unload all types. Confirm exact items
   return to Inventory and a second unload-all is rejected without duplication.
7. Reload both types, repeat switching/holstering and run WeaponMetadataInspect 1,
   WeaponRuntimeLeaseSmokeTest 1, WeaponReleaseContractSmokeTest 1 and weaponruntime.

Stop on a pool warning, failed checkpoint, missing count or free rounds; send
both consoles and wheel screenshots. Shared sidearms/long guns and all other
native variants are separate gates after this passes.

Do not turn the option off while saved firearm pools contain ammunition. Unload
all opted-in types first; otherwise opt-out must reject, not discard, metadata.

## Cattleman lifecycle gate

Basic load, wheel switching, one shot per type, resource restart, selected-type
unload and all-type unload have passed manual testing. The redesigned menu also
opens after preserving accordion keys. These do not establish lifecycle or broad
catalog acceptance. Keep the allowlist Cattleman-only for the following checks.

1. Load 10 Regular and 10 Express from owned Inventory ammunition. Record both
   Inventory quantities and saved pools; loading must subtract exactly 10 each.
2. Switch without firing, holster, unequip and re-equip. Both pools must stay 10.
3. Fire two rounds of one type, reload, then switch. Only that pool becomes 8;
   the other stays 10. Check loaded and reserve counts as well as totals.
4. Log out through the normal character flow and reconnect. Confirm 8/10 and
   the selected type persist; also check the menu can reopen.
5. On a development character, test death/respawn with the same recorded counts.
   Separate any configured death inventory policy from ammo checkpoint behavior.
6. Restore throwing-knife/Tomahawk ammo from existing Inventory, then repeat a
   Weapons restart. Their saved and native totals must agree and remain independent.
7. Run WeaponMetadataInspect 1, WeaponRuntimeLeaseSmokeTest 1,
   WeaponReleaseContractSmokeTest 1 and weaponruntime; provide both consoles on failure.

Stop on free rounds, lost pools, restore failure, or checkpoint warnings. No SQL
changes or additional item grants are required when the ammo is already owned.

## Distinct shoulder/back repeater gate

The experimental allowlist now includes repeater_carbine and repeater_lancaster.
Single and distinct dual revolver manual gates have passed, including mixed
selected types and isolated unload; death handling remains deferred.

Unequip the Bow to free the shoulder slot. Keep tested revolvers holstered.
Grant the two repeaters only if not already owned; equip Carbine on shoulder and
Lancaster on back. Empty weapons must have zero saved/loaded ammunition.
Load 10 Regular and 10 Express into each through slot-specific ammo management.
Inventory must lose exactly 20 of each repeater type overall. Native aggregate
totals must be Regular 20 and Express 20, with 10 per item per type. Check
weaponruntime and WeaponMetadataInspect 1 before firing. Stop on any warning.

Later gates cover per-instance firing, shared/different selected types, reload,
isolated unload, restart and normal reconnect. No item seeds or SQL are needed.
