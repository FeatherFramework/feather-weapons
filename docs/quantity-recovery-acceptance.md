# Regular Tomahawk quantity acceptance — 2026-11-15

Companion changes: [Weapons #50](https://github.com/FeatherFramework/feather-weapons/pull/50)
and [Inventory #70](https://github.com/FeatherFramework/feather-inventory/pull/70).
The framework Weapons and Inventory master plans remain the authoritative record.

## Live-confirmed scope

| Gate | Result |
| --- | --- |
| Paid load/unload; empty-inventory ammunition access | Passed |
| Capacity UI and pre-dispatch refusal | Passed; Load disabled at 3/3, concise localized reason |
| Own, shared and repeated native recovery | Passed |
| Three outstanding paid throws | Passed |
| Full native holder | Passed; pickup suppressed at three, re-enabled after unload, suppressed again on recovery to three |
| Multi-unit pickup | Passed; zero to three across two acknowledged pickup transactions, so at least one credited multiple units |
| Reconnect and full-server restart | Passed; loaded/unloaded quantities preserved |
| Death/admin revive | Passed; automatic seal, cleanup and fresh-epoch restoration |
| Return to Selection; Save and Quit | Passed on subsequent controlled runs |
| Prepared resource stop/start | Passed with exact cleanup and restored saved counts |
| Settled unprepared resource stop | Cleanup/release correctly refused; inspector confirmed native remnants; full RedM exit and resource restart/rejoin restored saved balance |
| Expiry rejection | Passed using a five-second test allowance; no credit, native excess removed, runtime active |
| Distance rejection | Passed using a test allowance recorded 100 metres away; no player/entity move |
| Bucket rejection | Passed with allowance bucket 1 and actual bucket 0; no player routing change |

Final observed Jane state: active, saved/native Tomahawks three at revision 60,
revolver regular 100, firearm and five melee assignments retained, Tomahawk drawable.
Historical serialized items were not converted, refunded or deleted.

## Controlled rejection diagnostics

These are console-only, default-off one-shot diagnostics. They share one current
session/epoch/revision reservation, expire if not used within 60 seconds, and
affect only the next single paid throw. They do not issue replacement ammunition
or edit balances. Each rejected recovery spends a real paid test unit.

| Console command (replace player ID) | Required temporary server convar | Test allowance |
| --- | --- | --- |
| `WeaponQuantityExpiryTest arm <id>` | `set feather_quantity_expiry_test 1` | Lifetime five seconds |
| `WeaponQuantityDistanceTest arm <id>` | `set feather_quantity_distance_test 1` | Recorded position shifted 100 metres on x; normal lifetime |
| `WeaponQuantityBucketTest arm <id>` | `set feather_quantity_bucket_test 1` | Recorded in the next bucket; maximum bucket wraps to zero |

Each command also supports `status <id>` and `cancel <id>`. Save status before
cancelling. Disable all three test convars afterward; never persist them in
server.cfg. Ordinary allowances remain at 180 seconds, 50 metres and the actual
server-recorded bucket. A test switch alone does not alter normal throws.
Unused distance/bucket test allowances expire naturally after 180 seconds.

## Limits of the evidence

Natural long-delay collection was inconclusive because the engine despawned the
object first. Controlled tests exercise actual server predicates and normal
native compensation, not physical projectile movement or live player bucket
migration. The precise sizes/order of the two observed pickup transactions were
not logged separately. SQL rollback/race coverage is modeled, not a contention
certification. Literal process crash, in-flight SQL crash and in-place hot restart
over retained native copies are not accepted by these results.

An earlier logout checkpoint refusal was not reproduced after a fresh session;
its original cause remains unproven. The added client diagnostic exposes the
original refusal without changing the checkpoint result or retrying writes.

Quantity recovery intentionally accepts bounded nearby claims rather than exact
serialized projectile ownership. A modified client can consume an available
allowance, but cannot save more recovered units than confirmed paid throws supplied.
Knives, arrows, physical holder items and historical-item migration are outside
this regular Tomahawk acceptance scope.
