# Ammunition selection

Use an ammunition item in Inventory to select and load that type. The weapon
must be empty before changing types: unload its loaded rounds and reserve first.
Unloading returns the selected ammunition item, never the default as a substitute.
The selected type is saved in weapon metadata as ammo.type and restored on equip,
character login and resource restart. Existing untyped items use their definition's
default until a type is selected. No database schema change or crafting code is required.

Dual-wield pairs continue to use one shared ammunition type. Unload both before
switching; selection is saved for both items in one metadata transaction. Repeated
ammo uses fill the less-stocked weapon. Both identical and distinct pairs use this
rule. An offhand carrying a different selected type cannot be equipped into the pair.
The weapon wheel is restricted to the approved type; choose another through Inventory.

Definitions use ammunitionType for the default and ammunitionTypes for the allowlist.
Validation rejects duplicate/unknown types and a default missing from the allowlist.
The existing LeMat shotgun-barrel mode is still outside this cylinder-only implementation.

## Automated checks

From the feather-weapons folder, run with Lua 5.4:

```text
lua tests/ammunition.lua
```

The suite exercises every catalog weapon/ammunition combination, exact-type unload,
restore, shot accounting, shared-pair selection, stale leases, incompatible requests,
and injected inventory failures. It mocks Inventory; it does not emulate RedM natives.

## In-game acceptance

1. Restart feather-weapons. Equip a weapon and unload all ammunition.
2. Use a compatible special-ammo item from Inventory, then run `weaponstate` in F8.
   Check the printed ammo type/native name and inventory count change.
3. Fire, reload, then unload. Verify only fired rounds are missing and returned items
   have the same type. Try using another type while loaded: it must reject without
   consuming inventory. Try an incompatible family: it must reject.
4. Load special ammo again, logout/rejoin, and restart the resource. Check that its
   type, total and condition survive. Check native special-ammo effects in game.
5. Repeat with Cattleman/Schofield and Cattleman/Cattleman pairs. Start with both empty,
   use the same ammo twice, fire both hands, unload both, then change types. Verify
   the shared total and the exact returned items. Test both equip orders.
6. Repeat across pistol, repeater, rifle, shotgun, Varmint tranquilizer and Elephant.
   Native availability and special effects must be confirmed on the server's build.

Server-console regression commands (replace 1 with the player source):

```text
WeaponRuntimeLeaseSmokeTest 1
WeaponDualSlotContractSmokeTest 1
WeaponReleaseContractSmokeTest 1
```

Native signatures were verified against the public RedM native database:
https://github.com/alloc8or/rdr3-nativedb-data/blob/master/natives.json
The implementation uses hash selection for ordinary weapons and inventory GUID
selection for identical copies, before granting the selected ammo pool.
