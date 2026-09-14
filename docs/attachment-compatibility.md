# Attachment compatibility worksheet

Only verified native mappings are promoted from this worksheet into the live
catalog. Cosmetic materials, engravings, varnishes, wraps, and tints remain out
of scope until their representation and conflict rules are designed.

| Weapon | Slot | Attachment | Native component | Catalog state | Live state |
| --- | --- | --- | --- | --- | --- |
| Cattleman Revolver | Barrel | Cattleman Long Barrel | `COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG` | Shipped | Passed full lifecycle |
| Cattleman Revolver | Sight | Cattleman Wide Sight | `COMPONENT_REVOLVER_CATTLEMAN_SIGHT_WIDE` | Shipped | Passed full lifecycle |

## Wide Sight acceptance matrix

- Install consumes exactly one component item.
- Wide Sight and Long Barrel can coexist as independent slots.
- Ammunition, loaded count, condition, serial, item identity, and lease remain unchanged.
- Primary, offhand, holstered, logout/re-entry, resource restart, and server restart restore both components.
- Removal returns exactly one component item and preserves the Long Barrel.
- Duplicate installation, incompatible weapon, stale lease, and occupied sight slot fail without consumption.

Native mappings are cross-checked against the model-specific component table in
`femga/rdr3_discoveries/weapons/weapon_components.lua` and must still pass visual
verification in the target RedM build.

## Definition rules

Attachment definitions declare explicit `conflicts` and `prerequisites` arrays.
Startup rejects unknown or self-referential prerequisites, prerequisite cycles,
conflicting prerequisite pairs, same-slot prerequisites, and prerequisites that
the weapon cannot install. Installation validates the complete resulting set
before consuming the component item. Removal likewise validates the remaining
set, so a prerequisite cannot be removed while an installed component depends
on it. Current shipped Cattleman components are independent and therefore use
empty prerequisite lists.

Weapons may also label the native baseline for each supported slot through
`attachmentDefaults`. Defaults are presentation metadata, not installed item
instances: they consume nothing, are not written to weapon metadata, and cannot
be removed into Inventory. The Cattleman exposes `Standard Barrel` and
`Standard Sight`; installing an upgrade replaces that slot's displayed default,
and removing the upgrade reveals the native default again.

## Wide Sight live result

The Wide Sight consumed and returned exactly one Inventory item, applied and
removed visibly, and preserved the Cattleman's identity, lease, ammunition, and
condition. It coexisted with the Long Barrel through resource restart, logout,
and full server restart in both primary and offhand roles. Duplicate installation
was unavailable without consuming the extra item, and an equipped Mauser exposed
no incompatible installation action.
