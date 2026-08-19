Config = {
    -- Gates the /AddAmmo dev command (server/services/commands.lua). Off by
    -- default -- same reasoning as feather-inventory's Config.DevMode
    -- (INV-05): a free-ammo command is not something to ship live. The
    -- command is also ACE-restricted, so flipping this on for testing still
    -- doesn't hand it to every player, only to principals explicitly
    -- granted `command.AddAmmo`.
    DevMode = false,

    -- Weapons listed here never get a usable-item callback registered (see
    -- server/services/equipping.lua), so they can't be equipped via the
    -- normal item-use flow even if a character holds one in inventory.
    blacklistedWeapons = {
        {
            weaponName = "WEAPON_PISTOL_M1899"
        }
    }
}