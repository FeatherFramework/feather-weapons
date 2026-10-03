# Advanced Camera equipment live gate

utility_camera_advanced / weapon_utility_camera_advanced / WEAPON_KIT_CAMERA_ADVANCED.
Fifth logical utility position: utility_quinary -> weapon_utility_quinary.
Equipment ownership, equip and persistence only. No photography controls or storage integration.
No ammunition, film, unlock writes or forced wheel placement.
Expected catalog: 45 weapons / 43 ammunition / 38 attachments.

1. Apply sql/add_advanced_camera.sql, reload Inventory definitions and deploy/restart Weapons.
2. grantweapon utility_camera_advanced 3 (replace with current server ID).
3. Equip alongside Standard Camera, Binoculars, Davy Lantern, one Lasso, four melee and all existing throwables.
4. Cycle both wheel pages. Confirm both cameras and all prior carriers remain selectable; report any suppression.
5. Draw/holster and switch between cameras, Binoculars, Lantern, melee, firearm and unarmed. No photography functionality is required for acceptance.
6. Confirm holders persist, no ammo-management entry, no stuck state or unintended ammo changes.
7. Unequip/re-equip Advanced Camera, restart twice and reconnect. Confirm both Camera IDs/serials persist.
8. WeaponMetadataInspect 3, WeaponRuntimeLeaseSmokeTest 3, WeaponReleaseContractSmokeTest 3; client weaponruntime and wheel screenshot.

Equipment wheel/metadata checks passed: supplied screenshot confirms Kit / Advanced Camera
and server/client snapshots confirm item 134 (FW-CAME-6AC0A4BD-5A63C5-0001)
coexisting with Standard Camera item 133, runtimeMatch=true and nativeOwned=true.
Lease checks passed 5/5 and release checks 9/9. Subsequent restart metadata retains
both serials. Photography remains explicitly outside Weapons scope.
Snapshots do not independently demonstrate every manual switch transition.
Static contracts pass; Lua regression execution unavailable locally.
