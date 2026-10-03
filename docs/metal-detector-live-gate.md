# Metal Detector live gate

utility_metal_detector / weapon_utility_metal_detector / WEAPON_KIT_METAL_DETECTOR.
Seventh utility position: utility_septenary -> weapon_utility_septenary.
Equipment only: no detecting, collectible spawning, rewards, custom controls or unlock writes.
Expected catalog: 48 weapons / 43 ammunition / 38 attachments. Live accepted: user confirmed manual checks; Metal Detector visible in Kit wheel, item 139 metadata/runtime match and native ownership; lease 5/5 and release 9/9, 24 active server slots.

1. Apply sql/add_metal_detector.sql, refresh Inventory definitions and deploy Weapons.
2. grantweapon utility_metal_detector 1 (substitute current source ID).
3. Equip with all six existing utility carriers, all melee and throwables.
4. Inspect both wheel pages for Metal Detector and confirm existing carriers remain available.
5. Draw, holster and switch to unarmed/other equipment; confirm no drops or lost ownership.
6. Confirm no ammunition-management entry, carrier consumption or existing ammo changes.
7. Unequip/re-equip, restart Weapons twice, reconnect. Confirm serial and equipment persist.
8. WeaponMetadataInspect 1, WeaponRuntimeLeaseSmokeTest 1, WeaponReleaseContractSmokeTest 1; client weaponruntime and screenshot.

Detection functionality is outside this gate and belongs to an optional add-on.
