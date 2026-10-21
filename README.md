# Feather Weapons

Feather's native-only, Inventory-backed firearm system. Weapons are unique
item instances; equipped assignments and maintenance persist per character.
Ammunition belongs to the character's shared pools, not individual weapons.

There is no legacy gameplay fallback, old-item conversion or alternate test
manifest deployment. Disabling native flags refuses startup instead of selecting
a different host. Preserve existing native test data until cutover verification;
no automatic database wipe or migration is performed.

## Current supported scope

This remains a development-scoped alpha with at most two explicitly enrolled
characters—not unrestricted production activation. Supported native firearms
use primary/offhand/shoulder/back positions, character ammunition, maintenance,
repair, admitted saved attachments, guarded ownership movement/provenance,
scoped evidence and receipt-backed pristine issuance.

Live controlled coverage includes two-player isolation, death/doctor recovery,
prepared resource/server restart, aggregate connected-owner drain, unequipped
give/return, equipped give refusal feedback, native issuance/replay/reconnect,
historical replay after transfer, and an uncustomized same-model Cattleman pair.

Limits remain: native non-firearm parity, destruction, customized same-model
pairs, wider enrollment, automatic shutdown interception, simultaneous SQL
contention and abrupt/in-flight crash outcomes are not generally accepted.
Admin roles and permissions are not changed by this work.

## Deployment and configuration

Use only the root `fxmanifest.lua`. Keep existing explicit native and feature
configuration; shipped defaults remain disabled. Required native host gates are
DevMode, NativeAlphaRuntime, CharacterAmmunitionEnabled,
CharacterAmmoTransportEnabled and valid explicit enrollment. Missing gates
refuse startup. Do not replace a customized config wholesale.

See [native-only cutover](docs/native-only-runtime-cutover.md) for the runtime
file list, required manifest refresh, and accepted loadout/history gate.
Before stopping an active Weapons host, run `WeaponNativePrepareStopAll` and
wait for aggregate PASS/ready. Failure is not permission to stop or retry.

Native issuance remains separately default-off:
`set feather_native_issuance 0`. See the
[issuance contract](docs/native-issuance-alpha.md) for stable request IDs,
historical receipt semantics and no-replacement behavior after uncertainty.

## Current guides

- [Controlled enrollment](docs/native-controlled-enrollment.md)
- [Aggregate shutdown preparation](docs/native-shutdown-drain-alpha.md)
- [Native issuance](docs/native-issuance-alpha.md)
- [Native-only cutover](docs/native-only-runtime-cutover.md)

The authoritative implementation status and acceptance record live in the
companion feather-framework-docs repository, under feather-weapons/
FEATHER_WEAPONS_MASTER_PLAN_NEXT.md and NATIVE_CUTOVER_REMAINING_WORK.md.
Older dated guides are evidence history, not alternate supported runtime modes.

## Historical tests

Retired scripts and temporary Jane manifests are isolated under
[tests/archive](tests/archive/README.md). Do not deploy that directory or load it
from the active manifest. Historical tests reproduce old evidence with mocks;
they do not establish current native parity or backward compatibility.

The former README is retained there as historical documentation only.
