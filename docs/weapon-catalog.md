# Standard firearm catalog

The catalog contains 24 standard models: four pistols, five revolvers,
four repeaters, six rifles (including scoped rifles and the Elephant Rifle),
and five shotguns. Named story-character and special cosmetic variants are
not included in this standard-model expansion.

Inventory names use the weapon_ prefix. Catalog IDs remain independent;
Lancaster maps to WEAPON_REPEATER_WINCHESTER and Litchfield to
WEAPON_REPEATER_HENRY. Scoped rifles use the WEAPON_SNIPERRIFLE natives.

All new entries inherit the existing condition policy: 100 maximum condition,
one condition per shot, and one gun_oil restoring 25 condition. New inventory
rows use the existing weapon defaults (weight 2, maximum quantity 20).
Only the existing Cattleman has a configured attachment slot.

The Varmint Rifle uses ammo_varmint. The Elephant Rifle uses
ammo_rifle_elephant (AMMO_RIFLE_ELEPHANT), bringing ammunition definitions to 27.
Regular ammunition is the default. Each weapon also declares its supported
ammunitionTypes: regular, express, high velocity, split point and explosive
for pistols/revolvers/repeaters/ordinary rifles; regular, slug, incendiary and
explosive shells for shotguns; regular and tranquilizer for Varmint; Nitro
Express only for Elephant. See ammunition-types.md for selection and testing.

LeMat capacity describes its nine-round revolver cylinder only. Secondary
shotgun-barrel ammunition selection is not implemented. Sawed-off is classified
as a sidearm, but existing offhand family policy still controls dual wield.
Adding longguns does not create additional equipment slots.

## Installation and verification

Run sql/install_items.sql with Inventory and Weapons stopped, then start both.
Existing installations using the old inventory names must first run
sql/rename_weapon_item_names.sql as described in the README.

Run WeaponReleaseContractSmokeTest 1; expected counts are
weapon=24 ammunition=27 attachment=1.

Live-test each new model: grant, equip, refill, fire, reload, unload, repair,
logout/rejoin, and verify native clip capacity against the configured capacity.
The catalog expansion itself does not establish that all native behaviors have
passed those tests. In particular, check LeMat mode changes and longgun holstering.

Native identifiers were cross-checked against:
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapons.lua
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/ammo_types.lua
