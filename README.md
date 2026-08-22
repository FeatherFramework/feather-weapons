# Feather Weapons

Feather Weapons is the weapons system for the Feather Framework. It manages equipped weapons, ammunition, weapon condition, repairs, and reconnect restoration.

> [!WARNING]
> Feather Weapons is currently a development preview. It is suitable for testing, but it is not ready for a production server because the included inventory provider stores data in memory. Player data survives reconnects but is lost when the resource or server restarts.

## What works today

The current build includes one complete test weapon: the Cattleman Revolver.

- Equip and unequip a character-owned weapon.
- Restore the equipped weapon after reconnecting.
- Load ammunition from the character's reserve supply.
- Save remaining ammunition after firing.
- Reduce weapon condition when shots are fired.
- Save weapon condition across reconnects.
- Consume repair kits to restore condition.
- Prevent broken weapons from being equipped or reloaded.
- Repair broken weapons and equip them again.
- Reject weapon actions when the character session or inventory state is invalid.

## What is not ready

- Weapon and ammunition data does not yet survive a resource or server restart.
- Only the Cattleman Revolver is configured for the current test slice.
- Physical ammunition unloading is disabled because RedM does not reliably remove rounds from a loaded weapon on the tested runtime. Enabling it would allow ammunition duplication.
- Weapon shops, crafting, attachments, transfers, storage, drops, evidence, licenses, job restrictions, and admin tools are not implemented yet.
- A production Feather Inventory integration is still required.

## Requirements

- A RedM server.
- `feather-core` with character-session contract version 1.
- `feather-core` must start before `feather-weapons`.

Current start order:

```cfg
ensure feather-core
ensure feather-weapons
```

## Installation for testing

1. Place `feather-weapons` in your server resources.
2. Ensure the updated `feather-core` is installed.
3. Confirm development mode and the test inventory provider are enabled in `config.lua`.
4. Add the resources to `server.cfg` in the order shown above.
5. Restart the server and select a character.

Current testing configuration:

```lua
Config = {
    DevMode = true,
    StrictStartup = true,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 1,
        allowTestAdapter = true
    }
}
```

> [!CAUTION]
> Do not use `allowTestAdapter = true` on a production server. The test provider is not connected to the database.

## Test commands

These commands are available only while development mode and the test provider are enabled.

| Command | Description |
| --- | --- |
| `/testweapon` | Equip your test Cattleman Revolver |
| `/testweaponoff` | Unequip the current weapon |
| `/testreload` | Fill the weapon from reserve ammunition |
| `/testreload 3` | Load up to three rounds |
| `/testweaponstate` | Show authoritative loaded ammo and condition in F8 |
| `/testrepair` | Use one repair kit on the test Cattleman |

Each test character receives:

- One empty Cattleman Revolver
- 24 revolver cartridges
- Three repair kits

## Recommended test process

1. Select a character and run `/testweapon`.
2. Run `/testreload` and confirm the revolver contains six rounds.
3. Fire three rounds.
4. Run `/testweaponstate`.
5. Confirm F8 reports three loaded rounds and condition 97.
6. Disconnect and reconnect with the same character.
7. Run `/testweaponstate` again and confirm the same values.
8. Run `/testrepair` and confirm condition returns to 100.
9. Run `/testrepair` again and confirm it is rejected because the weapon is already fully repaired.

Example output:

```text
[feather-weapons] state equipped=true loaded=3 condition=97
[feather-weapons] repair restored=3 condition=100 kits=2
```

More detailed testing notes are available in [docs/development-equip-slice.md](docs/development-equip-slice.md).

## Current weapon settings

| Setting | Cattleman Revolver |
| --- | --- |
| Capacity | 6 rounds |
| Starting condition | 100 |
| Condition loss | 1 per shot |
| Broken threshold | Below 1 |
| Repair material | 1 weapon repair kit |
| Repair amount | Up to 25 condition |

Weapon settings are definition-driven and will be expanded after the first lifecycle is fully proven.

## Persistence behavior

| Event | Current result |
| --- | --- |
| Character reconnect | Equipped weapon, ammo, and condition restore |
| Character logout | Native weapon state is cleared safely |
| Resource restart | Test data is lost |
| Server restart | Test data is lost |
| Production database save | Waiting for the real inventory provider |

## Known limitation: unloading ammunition

The `/testunload` command and unload API are intentionally unavailable. On the tested RedM runtime, documented ammunition-removal natives report success without reducing the physical rounds in the weapon. Returning those rounds to inventory would create a duplication exploit.

Loaded rounds therefore remain attached to the weapon until they are fired.


## Production readiness checklist

Do not move this resource to production until:

- The real Feather Inventory provider is installed.
- Weapon, ammunition, condition, equipped state, and repair materials survive resource and server restarts.
- Development mode and the test provider are disabled.
- Production item definitions and database migrations are installed.
- Security, concurrency, restart, and multiplayer tests pass.
- Required admin and recovery tools are available.

## For developers

Weapons are unique inventory item instances. The database-backed item metadata is authoritative; the RedM weapon is only its temporary in-game representation.

```lua
local Weapons = exports["feather-weapons"]:initiate()
local capabilities = Weapons.GetCapabilities()
```

Current server exports provide capability discovery, definition reads, metadata validation, runtime lookup, and inventory-provider installation. The client export provides equip, unequip, reload, repair, and reconciliation requests.

All operations use a consistent success or failure result:

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

## Planned next work

1. Weapon creation, serial generation, and provenance.
2. Production inventory and database persistence.
3. Audit records and administrative operations.
4. Attachments and weapon ownership lifecycle.
5. Transfers, storage, drops, evidence, and destruction.
6. Shops, licenses, jobs, user interfaces, and release hardening.
