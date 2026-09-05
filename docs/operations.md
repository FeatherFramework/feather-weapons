# Feather Weapons Operations

## Ownership model

Inventory is authoritative for weapon ownership, unique item identity, serials,
condition, attachments, and accepted ammunition. RedM owns the live weapon,
draw/fire/reload behavior, animation, and contextual controls. Feather creates a
native weapon only for the currently equipped Inventory instance.

Client reports may decrease the active ammunition budget or redistribute its
loaded/reserve split. They cannot increase persisted ammunition, create an item,
change the item instance, or reuse a stale lease generation. Inventory
transactions and metadata revisions remain authoritative.

Shot consumption is observed on the client because RedM does not provide a
trusted server-side shot ledger. A modified client can waste its own ammunition
or condition by reporting decreases, but cannot use this contract to gain
persistent ammunition or Inventory items. Treat anomaly logs as diagnostics,
not automatic proof of cheating.

## Installation and startup

Start Core, Character, Inventory, and Menu before Weapons. Use the recipe seed
for a clean installation, or run `sql/install_items.sql` after Inventory has
created its schema. Incompatible contracts and missing definitions always fail
startup closed; there is no partial-start option.

Weapons also validates every required Inventory definition at startup. The
Cattleman must be a usable unique weapon; revolver ammunition and gun oil
must be usable stacks; the Long Barrel must be a non-usable stack because it is
installed through the gunsmith menu. Missing names, duplicates, or mismatched
types/modes abort startup instead of disabling only part of the system.

Production defaults disable `DevMode` and the native probe. Enable them only on
a controlled development server, then disable them again before release.

## Recovery

Run `WeaponMetadataInspect [serverId]` from the server console first. It validates
the persisted equipped instance and reports its serial, ammunition, condition,
attachments, and whether the runtime references the same item.

If the runtime is inconsistent, run `WeaponReconcile [serverId]`. Reconciliation
invalidates the current lease generation, clears the native representation, and
restores the last accepted Inventory snapshot. It deliberately discards native
changes that were never accepted by the server.

Do not edit weapon metadata manually while a character is online. Restore the
database from backup for database corruption; reconciliation is not a schema or
data-repair tool.

## Integration

Trusted server resources issue unique weapons through:

```lua
local result = exports['feather-weapons']:IssueWeapon(request, context)
```

Use the named export at call time instead of retaining functions returned by
`initiate()` across a Weapons restart. Admin follows this rule for issuance and
re-resolves the catalog API whenever it is used.

Character logout uses an owner-scoped named checkpoint export. Character waits
for the final accepted weapon snapshot before beginning Core session teardown;
the later logout event performs native cleanup only.

## Expected boundaries

- Logout waits for a final acknowledged checkpoint.
- Death checkpoints immediately and retains the active lease through revive.
- Hard disconnect restores the last already accepted bounded checkpoint.
- Character switching clears the old native weapon before restoring another
  character's persisted instance.
- Weapons restart clears native state and rehydrates active Core sessions.
- Server restart rehydrates only persisted Inventory state.
