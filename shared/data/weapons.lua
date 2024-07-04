-- CREDIT TO: https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/weapons/weapons.lua

WeaponList = {
    -- Melee
    {weaponName = 'WEAPON_MELEE_KNIFE_JAWBONE', weaponGroup = 'group_melee'},                                      -- {0x1086D041,0xD49321D4},
    {weaponName = 'WEAPON_MELEE_MACHETE', weaponGroup = 'group_melee'},                                            -- {0x28950C71,0xD49321D4},
    {weaponName = 'WEAPON_MELEE_TORCH', weaponGroup = 'group_melee'},                                              -- {0x67DC3FDE,0xD49321D4},
    {weaponName = 'WEAPON_MELEE_KNIFE', weaponGroup = 'group_melee'},                                              -- {0xDB21AC8C,0xD49321D4},
    {weaponName = 'WEAPON_MELEE_MACHETE_HORROR', weaponGroup = 'group_melee'},
    {weaponName = 'WEAPON_MELEE_KNIFE_TRADER', weaponGroup = 'group_melee'},
    {weaponName = 'WEAPON_MELEE_MACHETE_COLLECTOR', weaponGroup = 'group_melee'},
    {weaponName = 'WEAPON_MELEE_KNIFE_HORROR', weaponGroup = 'group_melee'},
    {weaponName = 'WEAPON_MELEE_KNIFE_RUSTIC', weaponGroup = 'group_melee'},


    -- Sidearm
    {weaponName = 'WEAPON_PISTOL_VOLCANIC', weaponGroup = 'group_pistol'},                                         -- {0x020D13FF,0x18D5FA97},
    {weaponName = 'WEAPON_PISTOL_M1899', weaponGroup = 'group_pistol'},                                            -- {0x5B78B8DD,0x18D5FA97},
    {weaponName = 'WEAPON_PISTOL_SEMIAUTO', weaponGroup = 'group_pistol'},                                         -- {0x657065D6,0x18D5FA97},
    {weaponName = 'WEAPON_PISTOL_MAUSER', weaponGroup = 'group_pistol'},                                           -- {0x8580C63E,0x18D5FA97},
    {weaponName = 'WEAPON_REVOLVER_DOUBLEACTION', weaponGroup = 'group_revolver'},                                 -- {0x0797FBF5,0xBE5B8969},
    {weaponName = 'WEAPON_REVOLVER_CATTLEMAN', weaponGroup = 'group_revolver'},                                    -- {0x169F59F7,0xBE5B8969},
    {weaponName = 'WEAPON_REVOLVER_CATTLEMAN_MEXICAN', weaponGroup = 'group_revolver'},                            -- {0x16D655F7,0xBE5B8969},
    {weaponName = 'WEAPON_REVOLVER_LEMAT', weaponGroup = 'group_revolver'},                                        -- {0x5B2D26B5,0xBE5B8969},
    {weaponName = 'WEAPON_REVOLVER_SCHOFIELD', weaponGroup = 'group_revolver'},                                    -- {0x7BBD1FF6,0xBE5B8969},
    {weaponName = 'WEAPON_REVOLVER_DOUBLEACTION_GAMBLER', weaponGroup = 'group_revolver'},                         -- {0x83DD5617,0xBE5B8969},
    {weaponName = 'WEAPON_REVOLVER_NAVY', weaponGroup = 'group_revolver'},
    {weaponName = 'WEAPON_REVOLVER_NAVY_CROSSOVER', weaponGroup = 'group_revolver'},


    -- Long Guns & Bows
    {weaponName = 'WEAPON_REPEATER_EVANS', weaponGroup = 'group_repeater'},                                        -- {0x7194721E,0xDC8FB3E9},
    {weaponName = 'WEAPON_REPEATER_HENRY', weaponGroup = 'group_repeater'},                                        -- {0x95B24592,0xDC8FB3E9},
    {weaponName = 'WEAPON_REPEATER_WINCHESTER', weaponGroup = 'group_repeater'},                                   -- {0xA84762EC,0xDC8FB3E9},
    {weaponName = 'WEAPON_REPEATER_CARBINE', weaponGroup = 'group_repeater'},                                      -- {0xF5175BA1,0xDC8FB3E9},

    {weaponName = 'WEAPON_RIFLE_SPRINGFIELD', weaponGroup = 'group_rifle'},                                        -- {0x63F46DE6,0x39D5C192},
    {weaponName = 'WEAPON_RIFLE_BOLTACTION', weaponGroup = 'group_rifle'},                                         -- {0x772C8DD6,0x39D5C192},
    {weaponName = 'WEAPON_RIFLE_VARMINT', weaponGroup = 'group_rifle'},                                            -- {0xDDF7BC1E,0x39D5C192},
    {weaponName = 'WEAPON_RIFLE_ELEPHANT', weaponGroup = 'group_rifle'},

    {weaponName = 'WEAPON_SHOTGUN_SAWEDOFF', weaponGroup = 'group_shotgun'},                                       -- {0x1765A8F8,0x33431399},
    {weaponName = 'WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC', weaponGroup = 'group_shotgun'},                            -- {0x2250E150,0x33431399},
    {weaponName = 'WEAPON_SHOTGUN_PUMP', weaponGroup = 'group_shotgun'},                                           -- {0x31B7B9FE,0x33431399},
    {weaponName = 'WEAPON_SHOTGUN_REPEATING', weaponGroup = 'group_shotgun'},                                      -- {0x63CA782A,0x33431399},
    {weaponName = 'WEAPON_SHOTGUN_SEMIAUTO', weaponGroup = 'group_shotgun'},                                       -- {0x6D9BB970,0x33431399},
    {weaponName = 'WEAPON_SHOTGUN_DOUBLEBARREL', weaponGroup = 'group_shotgun'},                                   -- {0x6DFA071B,0x33431399},

    {weaponName = 'WEAPON_SNIPERRIFLE_CARCANO', weaponGroup = 'group_sniper'},                                     -- {0x53944780,0xB7BBD827},
    {weaponName = 'WEAPON_SNIPERRIFLE_ROLLINGBLOCK', weaponGroup = 'group_sniper'},                                -- {0xE1D2B317,0xB7BBD827},

    {weaponName = 'WEAPON_BOW', weaponGroup = 'group_bow'},                                                         -- {0x88a8505c,0xb5fd67cd},
    {weaponName = 'WEAPON_BOW_IMPROVED', weaponGroup = 'group_bow'},


    -- Thrown
    {weaponName = 'WEAPON_MELEE_HATCHET', weaponGroup = 'group_thrown'},                                           -- {0x09E12A01,0x5C4C5883},
    {weaponName = 'WEAPON_MELEE_HATCHET_HUNTER', weaponGroup = 'group_thrown'},                                    -- {0x2A5CF9D6,0x5C4C5883},
    {weaponName = 'WEAPON_THROWN_MOLOTOV', weaponGroup = 'group_thrown'},                                          -- {0x7067E7A7,0x5C4C5883},
    {weaponName = 'WEAPON_THROWN_TOMAHAWK_ANCIENT', weaponGroup = 'group_thrown'},                                 -- {0x7F23B6C7,0x5C4C5883},
    {weaponName = 'WEAPON_THROWN_TOMAHAWK', weaponGroup = 'group_thrown'},                                         -- {0xA5E972D7,0x5C4C5883},
    {weaponName = 'WEAPON_THROWN_DYNAMITE', weaponGroup = 'group_thrown'},                                         -- {0xA64DAA5E,0x5C4C5883},
    {weaponName = 'WEAPON_MELEE_HATCHET_DOUBLE_BIT', weaponGroup = 'group_thrown'},                                -- {0xBCC63763,0x5C4C5883},
    {weaponName = 'WEAPON_THROWN_THROWING_KNIVES', weaponGroup = 'group_thrown'},                                  -- {0xD2718D48,0x5C4C5883},
    {weaponName = 'WEAPON_MELEE_CLEAVER', weaponGroup = 'group_thrown'},                                           -- {0xEF32A25D,0x5C4C5883},
    {weaponName = 'WEAPON_THROWN_BOLAS', weaponGroup = 'group_thrown'},
    {weaponName = 'WEAPON_THROWN_POISONBOTTLE', weaponGroup = 'group_thrown'},
    {weaponName = 'WEAPON_THROWN_BOLAS_HAWKMOTH', weaponGroup = 'group_thrown'},
    {weaponName = 'WEAPON_THROWN_BOLAS_IRONSPIKED', weaponGroup = 'group_thrown'},
    {weaponName = 'WEAPON_THROWN_BOLAS_INTERTWINED', weaponGroup = 'group_thrown'},

    -- Held
    {weaponName = 'WEAPON_MELEE_DAVY_LANTERN', weaponGroup = 'group_held'},                                          -- {0x4A59E501,0xC715F939},
    {weaponName = 'WEAPON_KIT_BINOCULARS', weaponGroup = 'group_held'},                                              -- {0xF6687C5A,0xC715F939},
    {weaponName = 'WEAPON_KIT_CAMERA', weaponGroup = 'group_held'},                                                  -- {0xc3662b7d,0xc715f939},
    {weaponName = 'WEAPON_KIT_CAMERA_ADVANCED', weaponGroup = 'group_held'},
    {weaponName = 'WEAPON_KIT_BINOCULARS_IMPROVED', weaponGroup = 'group_held'},
    {weaponName = 'WEAPON_KIT_METAL_DETECTOR', weaponGroup = 'group_held'},
    {weaponName = 'WEAPON_MELEE_LANTERN_HALLOWEEN', weaponGroup = 'group_held'},

    -- Fishing rod
    {weaponName = 'WEAPON_FISHINGROD', weaponGroup = 'group_fishingrod'},                                                  -- {0xaba87754,0x60b51da4},

    -- lasso
    {weaponName = 'WEAPON_LASSO', weaponGroup = 'group_lasso'},                                                       -- {0x7a8a724a,0x126210c3},
    {weaponName = 'WEAPON_LASSO_REINFORCED', weaponGroup = 'group_lasso'},

    -- Petrol Can
    {weaponName = 'WEAPON_MOONSHINEJUG_MP', weaponGroup = 'group_petrolcan'}
}