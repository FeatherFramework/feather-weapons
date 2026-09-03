# Feather Weapons

Feather Weapons is the database-backed weapon system for the Feather Framework. Weapons are unique inventory item instances; their loaded ammunition, condition, and identity live in item metadata, while equipped state is stored per character.

Server operation, recovery, integration, and trust boundaries are documented in
[`docs/operations.md`](docs/operations.md).

> [!WARNING]
> This alpha release supports primary and native dual-wield loadouts with
> distinct or matching weapon hashes. The current catalog contains the
> Cattleman and Schofield revolvers. The wider catalog, shops,
> transfers, evidence flows, and licenses are not included yet.

> [!IMPORTANT]
> This is a native-first implementation. RedM owns live draw, fire, reload, and
> contextual controls. Feather owns authorization, Inventory-backed ammunition
> budgets, condition, persistence, and reconciliation.

## Current features

- Equip a weapon by using its item in Feather Inventory.
- Equip a second supported sidearm and use RedM's native dual-wield controls.
- Keep matching-hash weapons distinct through native inventory GUIDs.
- Unequip it by using the same item again.
- Restore the equipped weapon after reconnects and resource or server restarts.
- Finish reconnect and resource-start restoration with equipped guns holstered.
- Reload with the player-remappable `R` key.
- Atomically escrow compatible ammunition into single or dual weapon loadouts.
- Return ammunition from either equipped slot without unequipping the pair.
- Persist loaded ammunition after firing.
- Apply and persist condition loss per shot.
- Select and repair either equipped weapon by using a repair kit in Inventory.
- Atomically consume the repair kit and update weapon condition.
- Prevent equipped weapon instances from being moved or destroyed.
- Reject stale, concurrent, invalid, or unauthorized mutations.
- Validate attachment definitions, slots, conflicts, and per-weapon compatibility at startup.
- Resolve active characters through Feather Core Contract 1 sessions.
- Preserve canonical UUID character IDs through issuance, equipment, and Inventory calls.

The configured weapons are the Cattleman and Schofield revolvers using standard
revolver ammunition.

Weapon definition and Inventory item IDs follow `<family>_<model>`; for
example, `revolver_cattleman` and `revolver_schofield`.

## Requirements

- RedM server
- `oxmysql`
- `feather-core` Contract 1 with the session capability
- Current `feather-character` with logout checkpoint support
- Current `feather-inventory` Contract 4 with transactions, item instances,
  named equipment slots, atomic metadata, equipment promotion, guards, and
  canonical character-ID capabilities
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
2. For an existing alpha database, run
   [`sql/rename_weapon_ids.sql`](sql/rename_weapon_ids.sql) once.
3. Run [`sql/install_items.sql`](sql/install_items.sql) after the Feather Inventory schema and migrations.
4. Confirm `revolver_cattleman` exists as a unique, usable inventory definition.
5. Ensure the resources in the order shown above.
6. Restart the server; do not use a resource refresh for database migrations.

The installation SQL adds standard revolver ammunition, weapon repair kits, and the Cattleman Long Barrel; marks only the weapon, ammunition, and repair kit usable; and enforces unique/stack modes. It is idempotent and can be rerun. Startup fails closed if a required definition is missing, duplicated, or has incompatible usable, type, or instance-mode values.

> [!NOTE]
> Weapon instances are created through the inventory transaction service with unique serials and complete metadata. When `DevMode = true`, authorized staff can issue the configured Cattleman with `/grantweapon revolver_cattleman` in chat, or `grantweapon revolver_cattleman [targetServerId]` from the server console.

## Configuration

```lua
Config = {
    DevMode = false,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 4,
        equipmentSlot = "weapon",
        equipmentSlots = {
            primary = "weapon",
            offhand = "weapon_offhand"
        }
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
    Offhand = {
        enabled = true,
        allowedFamilies = { revolver = true },
        allowedWeaponSlots = { sidearm = true },
        provisionNativeEntitlement = true,
        nativeEntitlements = {
            { itemName = "CLOTHING_ITEM_M_OFFHAND_000_TINT_001", slotId = 0xF20B6B4A },
            { itemName = "UPGRADE_OFFHAND_HOLSTER", slotId = 0x39E57B01 }
        },
        primaryAttachPoint = 2,
        offhandAttachPoint = 3
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

`Offhand.enabled` controls dual-slot equipment. The two allowlists use weapon
definition `family` and `slot` values; only entries set to `true` are accepted.
Keep automatic entitlement provisioning enabled unless another resource owns
RedM's offhand holster unlock. Testing confirmed that the upgrade entitlement
alone is insufficient: RedM also requires an offhand clothing entitlement.
Testing the available tint variants produced no visible cosmetic difference,
so Feather treats this item as a native inventory marker rather than character
styling. `nativeEntitlements` remains server-owned. Replace its clothing item
only after testing the alternative in game. Attach-point values should only be
changed for a tested setup.

Startup always fails closed when required dependencies, definitions, or contracts are unavailable. `Inventory.requiredContract` must match the contract feather-inventory reports from `GetCapabilities().value.contractVersion` -- it is checked before any definition, usable callback or guard is registered, and a version below it aborts installation rather than degrading to an empty index. `DevMode` enables diagnostic output and development-only weapon grants; disable it on production servers. Keep `authoritativeNativeAmmo = true` when Feather Weapons owns all weapons and ammunition. At weapon boundaries, this clears the player's native ammo—including ammo granted by other resources—before restoring the equipped inventory item's saved rounds.

Trusted server resources issue unique weapons through the stable named export:

```lua
local result = exports['feather-weapons']:IssueWeapon(request, context)
```

## Recovery commands

The following commands are server-console only:

- `WeaponMetadataInspect [serverId]` validates both named Inventory weapon slots
  and reports each serial, ammunition state, condition, attachments, generation,
  and runtime match.
- `WeaponReconcile [serverId]` discards unaccepted native state and restores the
  character's accepted primary/offhand Inventory snapshots with new lease
  generations.

Run the inspection command first. Reconciliation is an explicit recovery action,
not routine gameplay synchronization.

Players can change Feather's registered bindings in their Cfx key-binding settings. Unload defaults to `U`, and weapon modifications to `F6`. Reload remains the native RedM `R` action and is not registered or intercepted by Feather. The modification menu can also be opened with `/weaponmods`.

## Gameplay

### Equip and unequip

Use a weapon item to equip it. Use that same item again to unequip it. When the
configured offhand policy permits the weapon, using a second sidearm equips it
in the offhand slot. Using the primary item promotes the offhand weapon; using
the offhand item removes only that slot.

### Reload

Use a compatible ammunition stack while a matching weapon is equipped to
transfer cartridges transactionally into bounded weapon escrow. With two
weapons equipped, the less-stocked slot is filled first; repeated uses can fill
both slots. Refilling an empty revolver loads its cylinder when RedM grants the
positive native pool. After firing, press native `R` to reload. Feather observes
and persists each loaded/reserve distribution without intercepting the key.

### Unload

Press `U` with one or two weapons equipped. The server checkpoints the active
loadout, returns the better-stocked slot's loaded and reserve cartridges to
Inventory, and updates its metadata in one transaction. Repeated uses drain the
other slot as well.

### Condition and repair

Accepted shots lower condition according to the weapon definition. Use a
`weapon_repair_kit` from Inventory to restore up to 25 condition. When two
weapons are equipped, choose the primary or offhand weapon from the repair
menu. Full-condition, stale-slot, and invalid repairs do not consume a kit.

### Weapon modifications

Attachment installation and removal require proximity to a configured gunsmith bench. Equip the weapon at the Valentine bench, then press `F6` or use `/weaponmods` to install an owned compatible attachment or remove an installed one. The Long Barrel is not a usable item; the server verifies distance and ownership before starting the Inventory transaction.

## Current revolver settings

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

The read-only `WeaponRuntimeLeaseSmokeTest`,
`WeaponDualSlotContractSmokeTest`, and `WeaponReleaseContractSmokeTest`
commands remain available from the server console with `DevMode` disabled.
Development grants and native probes remain disabled.

## Known limitations

- The first Long Barrel attachment is available; additional attachment definitions remain unfinished.
- Alternate ammunition, expanded provenance, evidence, licenses, shops, and crafting remain planned.

## Validation status

The current release has passed Inventory Contract 4 startup gates, unique
issuance, both equip orders, alternating fire/reload, per-item condition,
slot-aware repair and attachments, movement guards, reconciliation, entitlement
recovery, reconnect/resource/server restart, Admin operations, and two-player
isolation. Matching-hash pair refill/unload and holstered restoration passed
manual checks. The final runtime, dual-slot, and release gates passed `5/5`,
`14/14`, and `8/8`; primary-only behavior also remains regression tested.

## Attachment phase

The first attachment vertical slice uses a Cattleman Long Barrel inventory item
mapped to `COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG`. Open `/weaponmods` or press
`F6`, choose the primary or offhand weapon when a pair is equipped, then install
or remove the component. Both operations validate the selected slot lease,
commit atomically, and rebuild the approved native pair without changing saved
ammunition or condition.

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

1. Complete male/female offhand entitlement validation.
2. Expand the weapon catalog one tested family at a time.
3. Add ammunition types and complete the modification catalog.
4. Add transfers, storage, evidence, destruction, and recovery flows.
5. Integrate shops, licenses, jobs, and crafting through public contracts.

See [`MASTER_PLAN_NEXT.md`](MASTER_PLAN_NEXT.md) for the expansion plan. The
completed native-first architecture and validation record remains in
[`MASTER_PLAN.md`](MASTER_PLAN.md).
