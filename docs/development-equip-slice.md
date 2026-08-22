# Development equip slice

The development inventory provider exists only to exercise the session-safe equip state machine while the real inventory contract is under construction. It never writes to the database and is disabled by default.

## Enable locally

Set both values in `config.lua`:

```lua
DevMode = true

Inventory = {
    requiredContract = 1,
    allowTestAdapter = true
}
```

Restart `feather-core` and `feather-weapons`, load a character, then use:

- `/testweapon` to request and acknowledge the character-bound mock Cattleman Revolver.
- `/testweaponoff` to request authoritative unequip.

The mock item ID is derived server-side as `dev:cattleman:<characterId>`. The provider rejects IDs belonging to another character.

## Expected behavior

- Equip requires a current core character session.
- A short-lived server authorization is issued only after mock item validation.
- The client applies the native weapon and acknowledges the authorization.
- Expired or invalid acknowledgements remove the temporary native weapon.
- A second equip is rejected until the current weapon is unequipped.
- Logout, disconnect, character teardown, or resource stop clears runtime/native state.

## Production boundary

Never enable the test adapter in production. With it disabled, capability discovery reports inventory unavailable and equip requests fail closed. The real inventory resource must install a provider implementing the documented capability, item lookup, and transaction functions.
## Ammunition test

The mock character starts with 24 reserve revolver cartridges and an empty weapon. Reserve ammunition and loaded ammunition persist across reconnects while the resource remains running.

- `/testreload` fills the equipped weapon up to its six-round capacity.
- `/testreload 2` loads at most two rounds.
- Firing reads RedM's post-shot native ammunition count, then submits a subtract-only checkpoint that updates ammo and condition in one transaction.
- `/testweaponstate` prints authoritative loaded ammo and condition; the Cattleman loses one condition point per accepted shot in development.

Suggested check: equip, reload, fire two rounds, disconnect, reconnect, and confirm the revolver restores with four loaded rounds. Unload is intentionally unavailable until the RedM runtime can reliably remove physical ammunition.
