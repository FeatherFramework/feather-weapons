# Feather Weapons

Feather Weapons is the database-backed weapon system for the Feather Framework. Weapons are unique inventory item instances; their loaded ammunition, condition, and identity live in item metadata, while equipped state is stored per character.

> [!WARNING]
> This resource is still a development preview. The Cattleman Revolver lifecycle is working end to end, but the full weapon catalog, weapon creation service, attachments, shops, transfers, and administrative recovery tools are not finished.

## Current features

- Equip a weapon by using its item in Feather Inventory.
- Unequip it by using the same item again.
- Restore the equipped weapon after reconnects and resource or server restarts.
- Reload with the player-remappable `R` key.
- Atomically remove compatible ammunition items during reloads.
- Persist loaded ammunition after firing.
- Apply and persist condition loss per shot.
- Repair the equipped weapon by using a repair kit in inventory.
- Atomically consume the repair kit and update weapon condition.
- Prevent equipped weapon instances from being moved or destroyed.
- Reject stale, concurrent, invalid, or unauthorized mutations.

The current configured weapon is the Cattleman Revolver using standard revolver ammunition.

## Requirements

- RedM server
- `oxmysql`
- `feather-core` with the character-session contract
- Current `feather-inventory` with transactions, item instances, guards, and equipment persistence

Recommended start order:

```cfg
ensure oxmysql
ensure feather-core
ensure feather-inventory
ensure feather-weapons
```

`feather-weapons` now requires the production Feather Inventory provider. The abandoned in-memory fallback has been removed.

## Installation

1. Install compatible versions of Feather Core and Feather Inventory.
2. Run [`sql/install_items.sql`](sql/install_items.sql) after the Feather Inventory schema and migrations.
3. Confirm `cattleman_revolver` exists as a unique, usable inventory definition.
4. Ensure the resources in the order shown above.
5. Restart the server; do not use a resource refresh for database migrations.

The installation SQL adds standard revolver ammunition and weapon repair kits, marks repair kits usable, and enforces unique/usable settings on the Cattleman definition. It is idempotent and can be rerun.

> [!NOTE]
> Weapon instances are created through the inventory transaction service with unique serials and complete metadata. When `DevMode = true`, authorized staff can use the development grant command to issue configured weapons for testing.

## Configuration

```lua
Config = {
    DevMode = true,
    StrictStartup = true,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 2,
        equipmentSlot = "weapon"
    },
    Runtime = {
        authorizationTtlMs = 5000,
        authoritativeNativeAmmo = true
    },
    Controls = {
        reload = {
            enabled = true,
            defaultKey = "R",
            command = "feather_weapon_reload",
            nativeControl = 0xE30CD707,
            disableNative = true
        },
        unload = {
            enabled = true,
            defaultKey = "U",
            command = "feather_weapon_unload"
        }
    },
    Logging = {
        level = "info"
    }
}
```

Keep `StrictStartup = true` so missing dependencies or contracts fail closed. `Inventory.requiredContract` must match the contract feather-inventory reports from `GetCapabilities().value.contractVersion` -- it is checked before any definition, usable callback or guard is registered, and a version below it aborts installation rather than degrading to an empty index. `DevMode` enables diagnostic output and development-only weapon grants; disable it on production servers. Keep `authoritativeNativeAmmo = true` when Feather Weapons owns all weapons and ammunition. At weapon boundaries, this clears the player's native ammo—including ammo granted by other resources—before restoring the equipped inventory item's saved rounds.

Players can change the registered reload and unload bindings in their Cfx key-binding settings. Reload defaults to `R`; unload defaults to `U`.

## Gameplay

### Equip and unequip

Use a weapon item to equip it. Use that same item again to unequip it. A different weapon cannot be equipped until the current weapon is unequipped.

### Reload

Press `R` with a weapon equipped. The server determines capacity and compatible ammunition, removes only the required inventory quantity, commits the loaded amount, then authorizes the client reload. Full weapons and missing compatible ammunition fail without changing inventory.

### Unload

Press `U` with a loaded weapon equipped. The server returns the loaded rounds to the character inventory and updates the weapon metadata in one transaction, then rebuilds the native weapon with the approved remaining load.

### Condition and repair

Accepted shots lower condition according to the weapon definition. Use a `weapon_repair_kit` from inventory to restore up to 25 condition on the equipped Cattleman. Full-condition and invalid repairs do not consume a kit.

## Current Cattleman settings

| Setting | Value |
| --- | --- |
| Capacity | 6 rounds |
| Ammunition | Standard revolver cartridges |
| Maximum condition | 100 |
| Wear | 1 condition per shot |
| Equip minimum | 1 condition |
| Repair cost | 1 weapon repair kit |
| Repair amount | Up to 25 condition |

## Persistence

| Event | Result |
| --- | --- |
| Character reconnect | Equipped weapon, loaded ammo, and condition restore |
| `feather-weapons` restart | Equipped state restores from the database |
| Server restart | Equipped state and item metadata restore from the database |
| Failed transaction | Ammo, repair materials, and metadata remain unchanged |
| Concurrent stale mutation | Rejected by inventory revision checks |

## Development diagnostics

When `DevMode = true`, `/weaponstate` prints the authoritative equipped item ID, loaded ammunition, and condition to F8. Normal equip, reload, unload, and repair testing uses gameplay interactions rather than test commands.

## Known limitations

- Only the Cattleman Revolver is configured.
- Switching directly between two equipped weapon items is not implemented; unequip first.
- Attachments, alternate ammunition, weapon creation/provenance, transfers, storage rules, drops, evidence, licenses, shops, crafting, and admin recovery remain planned.

## Developer API

```lua
local Weapons = exports["feather-weapons"]:initiate()
local capabilities = Weapons.GetCapabilities()
```

Server capabilities expose definition reads, metadata validation, runtime state, and feature availability. Client methods expose equip, unequip, reload, repair, and reconciliation requests.

Operations return a consistent result envelope:

```lua
{ ok = true, value = value, correlationId = correlationId }
```

```lua
{
    ok = false,
    error = {
        code = "WEAPON_ERROR_CODE",
        message = "Human-readable message",
        details = {}
    },
    correlationId = correlationId
}
```

## Next milestones

1. Expand and validate the full weapon and ammunition catalog.
2. Add attachments and customization transactions.
3. Add transfers, storage, drops, evidence, destruction, and recovery flows.
4. Add shops, licenses, jobs, crafting, admin tooling, and release hardening.

See [`MASTER_PLAN.md`](MASTER_PLAN.md) for the complete build plan.