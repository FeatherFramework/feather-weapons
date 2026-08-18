Config = {
    -- Weapons listed here never get a usable-item callback registered (see
    -- server/services/equipping.lua), so they can't be equipped via the
    -- normal item-use flow even if a character holds one in inventory.
    blacklistedWeapons = {
        {
            weaponName = "WEAPON_PISTOL_M1899"
        }
    }
}