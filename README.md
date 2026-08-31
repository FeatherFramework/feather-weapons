# Feather Weapons

Feather Weapons is the database-backed weapon system for the Feather Framework. Weapons are unique inventory item instances; their loaded ammunition, condition, and identity live in item metadata, while equipped state is stored per character.

Server operation, recovery, integration, and trust boundaries are documented in
[`docs/operations.md`](docs/operations.md).

> [!WARNING]
> This resource is still a development preview. The Cattleman Revolver lifecycle and Inventory Contract 2 integration are working end to end. Attachment foundations are now in development; the full catalog, installation gameplay, shops, transfers, and administrative recovery tools are not finished.

> [!IMPORTANT]
> This is a native-first implementation. RedM owns live draw, fire, reload, and
> contextual controls. Feather owns authorization, Inventory-backed ammunition
> budgets, condition, persistence, and reconciliation.

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
- Validate attachment definitions, slots, conflicts, and per-weapon compatibility at startup.
- Resolve active characters through Feather Core Contract 1 sessions.
- Preserve canonical UUID character IDs through issuance, equipment, and Inventory calls.

The current configured weapon is the Cattleman Revolver using standard revolver ammunition.

## Requirements

- RedM server
- `oxmysql`
- `feather-core` Contract 1 with the session capability
- Current `feather-character` with logout checkpoint support
- Current `feather-inventory` Contract 2 with transactions, item instances, guards, equipment persistence, and canonical character-ID capabilities
- `feather-menu` for the weapon modification screen

Recommended start order:

```cfg
ensure oxmysql
ensure feather-core
ensure feather-character
ensure feather-inventory
ensure feather-menu
ensure feather-weapons
```

`feather-weapons` now requires the production Feather Inventory provider. The abandoned in-memory fallback has been removed.

Weapons and Inventory require canonical UUID character IDs. Numeric legacy
character IDs are rejected and are not part of the release contract.

## Installation

1. Install compatible versions of Feather Core and Feather Inventory.
2. Run [`sql/install_items.sql`](sql/install_items.sql) after the Feather Inventory schema and migrations.
3. Confirm `cattleman_revolver` exists as a unique, usable inventory definition.
4. Ensure the resources in the order shown above.
5. Restart the server; do not use a resource refresh for database migrations.

The installation SQL adds standard revolver ammunition, weapon repair kits, and the Cattleman Long Barrel; marks only the weapon, ammunition, and repair kit usable; and enforces unique/stack modes. It is idempotent and can be rerun. Startup fails closed if a required definition is missing, duplicated, or has incompatible usable, type, or instance-mode values.

> [!NOTE]
> Weapon instances are created through the inventory transaction service with unique serials and complete metadata. When `DevMode = true`, authorized staff can issue the configured Cattleman with `/grantweapon cattleman_revolver` in chat, or `grantweapon cattleman_revolver [targetServerId]` from the server console.

## Configuration

```lua
Config = {
    DevMode = false,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 2,
        equipmentSlot = "weapon"
    },
    Runtime = {
        authorizationTtlMs = 5000,
        authoritativeNativeAmmo = true,
        observationIntervalMs = 50,
        checkpointDebounceMs = 250
    },
    Escrow = {
        maxTotal = 30,
        refillAmount = 30
    },
    Attachments = {
        requireStation = true,
        interactionDistance = 2.0,
        serverTolerance = 3.0,
        stations = {
            valentine = {
                label = "Valentine Gunsmith Bench",
                coords = vector3(-277.455, 779.197, 119.504)
            }
        }
    },
    Controls = {
        unload = {
            enabled = true,
            defaultKey = "U",
            command = "feather_weapon_unload"
        },
        modify = {
            enabled = true,
            defaultKey = "F6",
            command = "weaponmods"
        }
    }
}
```

Startup always fails closed when required dependencies, definitions, or contracts are unavailable. `Inventory.requiredContract` must match the contract feather-inventory reports from `GetCapabilities().value.contractVersion` -- it is checked before any definition, usable callback or guard is registered, and a version below it aborts installation rather than degrading to an empty index. `DevMode` enables diagnostic output and development-only weapon grants; disable it on production servers. Keep `authoritativeNativeAmmo = true` when Feather Weapons owns all weapons and ammunition. At weapon boundaries, this clears the player's native ammo—including ammo granted by other resources—before restoring the equipped inventory item's saved rounds.

Trusted server resources issue unique weapons through the stable named export:

```lua
local result = exports['feather-weapons']:IssueWeapon(request, context)
```

## Recovery commands

The following commands are server-console only:

- `WeaponMetadataInspect [serverId]` validates the equipped Inventory instance
  and reports its serial, ammunition, condition, attachments, and runtime match.
- `WeaponReconcile [serverId]` discards unaccepted native state and restores the
  character's last accepted Inventory snapshot with a new lease generation.

Run the inspection command first. Reconciliation is an explicit recovery action,
not routine gameplay synchronization.

Players can change Feather's registered bindings in their Cfx key-binding settings. Unload defaults to `U`, and weapon modifications to `F6`. Reload remains the native RedM `R` action and is not registered or intercepted by Feather. The modification menu can also be opened with `/weaponmods`.

## Gameplay

### Equip and unequip

Use a weapon item to equip it. Use that same item again to unequip it. A different weapon cannot be equipped until the current weapon is unequipped.

### Reload

Use a compatible ammunition stack while its weapon is equipped to transfer cartridges transactionally into that weapon's bounded escrow. Refilling a completely empty Cattleman loads its cylinder immediately because RedM does this natively when a positive ammunition pool is granted. After firing, press native `R` to reload from the approved reserve. Feather observes and persists the resulting loaded/reserve distribution without reading or disabling the key.

### Unload

Press `U` with an armed weapon equipped. The server returns its loaded and reserve cartridges to the character inventory and updates weapon metadata in one transaction, then clears the native ammunition pool.

### Condition and repair

Accepted shots lower condition according to the weapon definition. Use a `weapon_repair_kit` from inventory to restore up to 25 condition on the equipped Cattleman. Full-condition and invalid repairs do not consume a kit.

### Weapon modifications

Attachment installation and removal require proximity to a configured gunsmith bench. Equip the weapon at the Valentine bench, then press `F6` or use `/weaponmods` to install an owned compatible attachment or remove an installed one. The Long Barrel is not a usable item; the server verifies distance and ownership before starting the Inventory transaction.

## Current Cattleman settings

| Setting | Value |
| --- | --- |
| Capacity | 6 rounds |
| Escrow ceiling | 30 rounds total |
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
- The first Long Barrel attachment is available; additional attachment definitions remain unfinished.
- Alternate ammunition, expanded provenance, evidence, licenses, shops, and crafting remain planned.

## Validation status

The current vertical slice has passed runtime tests for Inventory Contract 2 startup gates, unique issuance, equip/unequip, reload/unload, firing and condition, repair, inventory movement guards, ground drop/pickup, cross-container movement, concurrency rejection, reconnect persistence, resource restart, and full server restart.

## Attachment phase

The first attachment vertical slice uses a Cattleman Long Barrel inventory item mapped to `COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG`. Using the item with a compatible weapon equipped installs it atomically. Open `/weaponmods` or press `F6` to remove it through the modification menu and atomically return the item. Both operations rebuild the approved native weapon without changing its saved ammunition or condition.

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

1. Runtime-test the Cattleman Long Barrel install/remove and restart lifecycle.
2. Replace the development removal command with the production gunsmith interaction.
3. Add transfers, storage, drops, evidence, destruction, and recovery flows.
4. Add shops, licenses, jobs, crafting, admin tooling, and release hardening.

See [`MASTER_PLAN.md`](MASTER_PLAN.md) for the complete build plan.
