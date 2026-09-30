# Weapon catalog

The catalog contains 24 standard firearms: four pistols, five revolvers,
four repeaters, six rifles (including scoped rifles and the Elephant Rifle),
and five shotguns. It also contains the standard Bow as the first
ammunition-using special weapon. Named story-character and special cosmetic
variants are not included.

Inventory names use the weapon_ prefix. Catalog IDs remain independent;
Lancaster maps to WEAPON_REPEATER_WINCHESTER and Litchfield to
WEAPON_REPEATER_HENRY. Scoped rifles use the WEAPON_SNIPERRIFLE natives.

All new entries inherit the existing condition policy: 100 maximum condition,
native RedM maintenance determines wear, and one gun_oil restores up to 25
condition without crossing the permanent-wear floor. New inventory rows use the
existing weapon defaults (weight 2, maximum quantity 20).
Configured attachment slots cover the live-validated standard firearm models.
The Bow currently declares no functional attachment slots.

The Varmint Rifle uses ammo_varmint. The Elephant Rifle uses
ammo_rifle_elephant (AMMO_RIFLE_ELEPHANT). The Bow uses
ammo_arrow_regular (AMMO_ARROW), Small Game Arrows (AMMO_ARROW_SMALL_GAME),
Poison Arrows (AMMO_ARROW_POISON), and Fire Arrows (AMMO_ARROW_FIRE), bringing
ammunition definitions to 31.
Regular and Small Game Arrows have a definition-level 40-arrow escrow ceiling;
Poison and Fire Arrows use the native eight-arrow special-ammunition ceiling.
Improved Arrows are intentionally excluded: live testing with the standard Bow
accepted the Inventory transfer but the native `AMMO_ARROW_IMPROVED` pool
remained at zero, so exposing that route would consume Inventory without making
the arrows usable.
Nitro Express has a definition-level 20-round escrow ceiling, so loading from a
larger Inventory stack moves at most 20 cartridges into the Elephant Rifle.
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
weapon=25 ammunition=31 attachment=38.

Live-test each new model: grant, equip, refill, fire, reload, unload, repair,
logout/rejoin, and verify native clip capacity against the configured capacity.
The catalog expansion itself does not establish that all native behaviors have
passed those tests. In particular, check LeMat mode changes and longgun holstering.

Native identifiers were cross-checked against:
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapons.lua
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/ammo_types.lua
