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

The standard Tomahawk is a completed throwable validation slice. Its unique
carrier maps to `WEAPON_THROWN_TOMAHAWK`, and regular Inventory-backed
tomahawks map to `AMMO_TOMAHAWK`. Live testing confirmed that the target RedM
build accepts and preserves a three-Tomahawk native pool, with metadata and the
ammunition-management UI reporting one readied and two in reserve. A second
persistent throwable position allows the Tomahawk carrier and Throwing Knives
carrier to coexist. Live testing confirmed both remain natively owned and can
be selected by cycling within RedM's shared throwable-wheel category, while
their distinct `AMMO_TOMAHAWK` and `AMMO_THROWING_KNIVES` pools remain
independent. Metadata inspection passed with seven active persistent slots;
runtime lease, release, and multi-slot contracts passed `5/5`, `9/9`, and
`17/17` respectively.
Subsequent metadata inspections confirmed that one Tomahawk throw persisted a
reduction from three to two, and same-player pickup restored the total to
three. Both checkpoints matched the active runtime; the co-equipped Throwing
Knives carrier remained at six throughout. Manual validation confirmed exact
return of three Tomahawks on unload, reload, and restoration of both carriers
after a Weapons resource restart. Post-restart metadata and native pools agreed
at three Tomahawks and six Throwing Knives, with runtime lease `5/5` and release
contract `9/9` passing. Cross-player pickup transfer remains deferred for both
families pending the server-owned projectile/pickup ledger described above.

Improved Tomahawk ammunition failed live validation on the target build.
After loading it into the standard carrier, the weapon disappeared from the
wheel and `AMMO_TOMAHAWK_IMPROVED` remained at zero. Runtime synchronization
persisted a zero ammunition total despite no successful throw. Lease and
release smoke tests still passed; those checks do not establish native ammo
support. Switching the test carrier back to Regular restored agreement at
three Tomahawks in metadata and the native pool, while co-equipped Throwing
Knives remained at six. The experimental definition, carrier compatibility,
and recipe seed were removed. Improved Tomahawks are excluded from release
on this build.
After removing the route and restarting Weapons, metadata inspection confirmed
both carriers restored at three regular Tomahawks and six Throwing Knives with
runtime matches. Runtime lease passed `5/5` and release contract passed `9/9`
with `weapon=31 ammunition=34 attachment=38`, completing rollback validation.

Homing Tomahawk ammunition also failed live validation through the standard
carrier on the target build. The wheel behavior matched the Improved test,
`AMMO_TOMAHAWK_HOMING` stayed at zero, and runtime synchronization persisted
zero ammunition without a successful throw. Co-equipped Throwing Knives stayed
at six; lease and release smoke tests passed `5/5` and `9/9`. This route is not
accepted for release. Returning to Regular restored metadata/native agreement
at three Tomahawks while Throwing Knives remained at six. The Homing definition,
carrier compatibility, and recipe seed were removed after that recovery.
Post-removal Weapons restart restored both carriers at those same totals with
all seven equipped slots matching runtime. Runtime lease passed `5/5` and
release contract passed `9/9` with `weapon=31 ammunition=34 attachment=38`,
completing Homing rollback validation.

Throwable consumption tracking now waits for the selected native pool to match
the approved escrow balance after restore or ammunition application. Until
that initial verification succeeds, checkpoints preserve the saved balance and
the owner can unload the exact selected ammunition type. A diagnostic identifies
the mismatch. This guard does not make
the excluded Improved or Homing routes supported. Regular Tomahawk regression
passed throw, self-recovery, and exact unload checks, with a final zero escrow
and unchanged six-knife balance. Lease and release checks passed `5/5` and `9/9`.
The DevMode-only `weaponthrowablepoolfailure <slot>` command simulates a fresh
native application by overriding the verification read to zero while preserving
the approved escrow and the real native pool. The fault belongs to the current
local observation and clears on unload/reconciliation or resource restart.
Do not throw while the fault is active. `weaponruntime` reports the real pool
separately from `simulatedFailure` and verification readiness.
Live fault-injection validation produced `approved=3 native=0` at the guard,
with `ready=false simulatedFailure=true`. Metadata inspection retained all
three escrowed Tomahawks while the simulated mismatch was active. Subsequent
unload left the carrier at zero; Throwing Knives remained at six throughout.
Runtime lease and release contract passed `5/5` and `9/9`. The real native pool
remained three during this synthetic test, so this proves handling of the
injected verification mismatch rather than native support for excluded types.
Manual confirmation verified that exactly three regular Tomahawks returned to
Inventory on unload, completing the injected-failure conservation check.

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
weapon=31 ammunition=34 attachment=38.

Live-test each new model: grant, equip, refill, fire, reload, unload, repair,
logout/rejoin, and verify native clip capacity against the configured capacity.
The catalog expansion itself does not establish that all native behaviors have
passed those tests. In particular, check LeMat mode changes and longgun holstering.

Native identifiers were cross-checked against:
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/weapons.lua
- https://github.com/femga/rdr3_discoveries/blob/master/weapons/ammo_types.lua
