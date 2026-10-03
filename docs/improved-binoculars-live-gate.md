# Improved Binoculars live gate

Definition utility_binoculars_improved; item weapon_utility_binoculars_improved;
native WEAPON_KIT_BINOCULARS_IMPROVED. Reuses utility_senary / weapon_utility_senary.
Expected catalog: 47 weapons / 43 ammunition / 38 attachments.
No ammunition, unlock changes or custom gameplay controls. Live accepted: user confirmed all manual checks; native wheel label Refined Binoculars. Item 138 metadata matches runtime, nativeOwned=true; 23 active slots, lease 5/5 and release 9/9 passed.

1. Apply sql/add_improved_binoculars.sql, refresh Inventory definitions and deploy Weapons/Recipe changes.
2. grantweapon utility_binoculars_improved 1 (substitute current server ID).
3. Equip with standard Binoculars, one Lasso, Davy Lantern and both cameras; confirm sixth utility slot.
4. Check Items wheel Kit category; test whether both Binoculars remain selectable. Capture native label.
5. Draw, try native viewing controls, switch/holster. Confirm no dropped equipment or suppressed unrelated carriers.
6. Confirm no ammo-management entry or altered ammo totals.
7. Unequip/re-equip; restart Weapons twice and reconnect. Confirm same carrier identity/serial and loadout.
8. Run WeaponMetadataInspect 1, WeaponRuntimeLeaseSmokeTest 1, WeaponReleaseContractSmokeTest 1 and client weaponruntime.

If missing from the wheel, test once with standard Binoculars unequipped and report the difference.
Do not treat nativeOwned=true or clipOk as functional acceptance for ammunition-free equipment.
