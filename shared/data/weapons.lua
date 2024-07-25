-- CREDIT TO: https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/weapons/weapons.lua
-- There are 4 weapon slots: melee, pistol, longgun, throwable

WeaponList = {
    -- Melee
    ['WEAPON_MELEE_KNIFE_JAWBONE'] = {weaponGroup = "group_melee", weaponSlot = "melee"},
    ['WEAPON_MELEE_MACHETE'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_TORCH'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_KNIFE'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_MACHETE_HORROR'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_KNIFE_TRADER'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_MACHETE_COLLECTOR'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_KNIFE_HORROR'] = { weaponGroup = "group_melee", weaponSlot = "melee" },
    ['WEAPON_MELEE_KNIFE_RUSTIC'] = { weaponGroup = "group_melee", weaponSlot = "melee" },

    -- Sidearm
    ['WEAPON_PISTOL_VOLCANIC'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_PISTOL_M1899'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_PISTOL_SEMIAUTO'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_PISTOL_MAUSER'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_DOUBLEACTION'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_CATTLEMAN'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_CATTLEMAN_MEXICAN'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_LEMAT'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_SCHOFIELD'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_DOUBLEACTION_GAMBLER'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_NAVY'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_REVOLVER_NAVY_CROSSOVER'] = { weaponGroup = "group_pistol", weaponSlot = "pistol" },
    ['WEAPON_SHOTGUN_SAWEDOFF'] = { weaponGroup = "group_shotgun", weaponSlot = "pistol" },

    -- Long Guns & Bows
    ['WEAPON_REPEATER_EVANS'] = { weaponGroup = "group_repeater", weaponSlot = "longgun" },
    ['WEAPON_REPEATER_HENRY'] = { weaponGroup = "group_repeater", weaponSlot = "longgun" },
    ['WEAPON_REPEATER_WINCHESTER'] = { weaponGroup = "group_repeater", weaponSlot = "longgun" },
    ['WEAPON_REPEATER_CARBINE'] = { weaponGroup = "group_repeater", weaponSlot = "longgun" },

    ['WEAPON_RIFLE_SPRINGFIELD'] = { weaponGroup = "group_rifle", weaponSlot = "longgun" },
    ['WEAPON_RIFLE_BOLTACTION'] = { weaponGroup = "group_rifle", weaponSlot = "longgun" },
    ['WEAPON_RIFLE_VARMINT'] = { weaponGroup = "group_rifle", weaponSlot = "longgun" },
    ['WEAPON_RIFLE_ELEPHANT'] = { weaponGroup = "group_rifle", weaponSlot = "longgun" },

    ['WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun" },
    ['WEAPON_SHOTGUN_PUMP'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun" },
    ['WEAPON_SHOTGUN_REPEATING'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun" },
    ['WEAPON_SHOTGUN_SEMIAUTO'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun" },
    ['WEAPON_SHOTGUN_DOUBLEBARREL'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun" },

    ['WEAPON_SNIPERRIFLE_CARCANO'] = { weaponGroup = "group_sniper", weaponSlot = "longgun" },
    ['WEAPON_SNIPERRIFLE_ROLLINGBLOCK'] = { weaponGroup = "group_sniper", weaponSlot = "longgun" },

    ['WEAPON_BOW'] = { weaponGroup = "group_bow", weaponSlot = "longgun" },
    ['WEAPON_BOW_IMPROVED'] = { weaponGroup = "group_bow", weaponSlot = "longgun" },

    -- Thrown
    ['WEAPON_MELEE_HATCHET'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_MELEE_HATCHET_HUNTER'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_MOLOTOV'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_TOMAHAWK_ANCIENT'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_TOMAHAWK'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_DYNAMITE'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_MELEE_HATCHET_DOUBLE_BIT'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_THROWING_KNIVES'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_MELEE_CLEAVER'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_BOLAS'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_POISONBOTTLE'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_BOLAS_HAWKMOTH'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_BOLAS_IRONSPIKED'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },
    ['WEAPON_THROWN_BOLAS_INTERTWINED'] = { weaponGroup = "group_thrown", weaponSlot = "throwable" },

    -- Held
    ['WEAPON_MELEE_DAVY_LANTERN'] = { weaponGroup = "group_held", weaponSlot = "melee" },
    ['WEAPON_KIT_BINOCULARS'] = { weaponGroup = "group_held", weaponSlot = "melee" },
    ['WEAPON_KIT_CAMERA'] = { weaponGroup = "group_held", weaponSlot = "melee" },
    ['WEAPON_KIT_CAMERA_ADVANCED'] = { weaponGroup = "group_held", weaponSlot = "melee" },
    ['WEAPON_KIT_BINOCULARS_IMPROVED'] = { weaponGroup = "group_held", weaponSlot = "melee" },
    ['WEAPON_KIT_METAL_DETECTOR'] = { weaponGroup = "group_held", weaponSlot = "melee" },
    ['WEAPON_MELEE_LANTERN_HALLOWEEN'] = { weaponGroup = "group_held", weaponSlot = "melee" },

    -- Fishing rod
    ['WEAPON_FISHINGROD'] = { weaponGroup = "group_fishingrod", weaponSlot = "melee" },

    -- lasso
    ['WEAPON_LASSO'] = { weaponGroup = "group_lasso", weaponSlot = "melee" },
    ['WEAPON_LASSO_REINFORCED'] = { weaponGroup = "group_lasso", weaponSlot = "melee" },

    -- Petrol Can
    ['WEAPON_MOONSHINEJUG_MP'] = { weaponGroup = "group_petrolcan", weaponSlot = "melee" }
}