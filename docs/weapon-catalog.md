# Weapon catalog

The catalog contains 24 standard firearms: four pistols, five revolvers,
four repeaters, six rifles (including scoped rifles and the Elephant Rifle),
and five shotguns. It also contains the standard Bow as the first
ammunition-using special weapon plus the standard Knife, Machete, Cleaver, and
Hatchet as ammunition-free melee weapons. Named story-character and special
cosmetic variants are not included.

Melee weapons use distinct persistent logical positions while sharing RedM's
single melee-wheel category. Live testing confirmed that the Knife and Machete
coexist and can be selected by cycling within that wheel category. The Knife is
visible while holstered. The Machete becomes visible only when selected and uses
its native cross-draw presentation. The Cleaver also coexists in that category,
cycles normally, and remains usable. Although its metadata is ammunition-free,
RedM requires one native grant unit to materialize this recoverable throwable
weapon in the wheel. The Hatchet is the fourth coexistence slice and uses the
same bounded native-grant rule. Live testing confirmed all four models remain
native-owned and selectable together; the Hatchet uses the same native draw
presentation as the Machete and Cleaver.

Throwing Knives begin the dedicated throwable catalog. The unique carrier uses
its own persistent throwable position while regular knives are Inventory-backed
ammunition mapped to `AMMO_THROWING_KNIVES`. Each native throw must reduce the
approved escrow rather than the unique carrier item. The target RedM build
clamps the native pool to eight, so excess knives remain in Inventory. Live
testing confirmed that two throws commit a reduction from eight to six. Picking
up those same world objects spends the recovery credit created by the committed
throws, restores the carrier escrow, and keeps the wheel and later unload in
agreement. Recovery cannot exceed the number previously thrown by that active
runtime lease, so unrelated native pickups cannot mint authoritative ownership.
Cross-player recovery is deferred: transferring a thrown knife to another
character requires a server-owned projectile/pickup ledger that identifies the
physical knife, consumes its entitlement exactly once, and credits the picker
without leaving recovery credit available to the thrower.

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
Poison Arrows (AMMO_ARROW_POISON), Fire Arrows (AMMO_ARROW_FIRE), and Dynamite
Arrows (AMMO_ARROW_DYNAMITE), bringing ammunition definitions to 32.
Regular and Small Game Arrows have a definition-level 40-arrow escrow ceiling;
Poison, Fire, and Dynamite Arrows use the native eight-arrow
special-ammunition ceiling.
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
weapon=30 ammunition=33 attachment=38.

Live-test each new model: grant, equip, refill, fire, reload, unload, repair,
logout/rejoin, and verify native clip capacity against the configured capacity.
The catalog expansion itself does not establish that all native behaviors have
passed those tests. In particular, check LeMat mode changes and longgun holstering.

Native identifiers were cross-checked against:
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapons.lua
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/ammo_types.lua
