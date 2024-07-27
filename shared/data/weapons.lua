-- CREDIT TO: https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/weapons/weapons.lua
-- There are 4 weapon slots: melee, pistol, longgun, throwable

WeaponList = {
    -- Melee
    ['WEAPON_MELEE_KNIFE_JAWBONE'] = {weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "knife_jawbone"},
    ['WEAPON_MELEE_MACHETE'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "machete" },
    ['WEAPON_MELEE_TORCH'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "torch" },
    ['WEAPON_MELEE_KNIFE'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "knife" },
    ['WEAPON_MELEE_MACHETE_HORROR'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "machete_horror" },
    ['WEAPON_MELEE_KNIFE_TRADER'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "knife_trader" },
    ['WEAPON_MELEE_MACHETE_COLLECTOR'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "machete_collector" },
    ['WEAPON_MELEE_KNIFE_HORROR'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "knife_horror" },
    ['WEAPON_MELEE_KNIFE_RUSTIC'] = { weaponGroup = "group_melee", weaponSlot = "melee", weaponDBName = "knife_rustic" },

    -- Sidearm
    ['WEAPON_PISTOL_VOLCANIC'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "volcanic_pistol" },
    ['WEAPON_PISTOL_M1899'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "m1899_pistol" },
    ['WEAPON_PISTOL_SEMIAUTO'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "semiauto_pistol" },
    ['WEAPON_PISTOL_MAUSER'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "mauser_pistol" },
    ['WEAPON_REVOLVER_DOUBLEACTION'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "doubleaction_revolver" },
    ['WEAPON_REVOLVER_CATTLEMAN'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "cattleman_revolver" },
    ['WEAPON_REVOLVER_CATTLEMAN_MEXICAN'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "mexican_cattleman_revolver" },
    ['WEAPON_REVOLVER_LEMAT'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "lemat_revolver" },
    ['WEAPON_REVOLVER_SCHOFIELD'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "schofield_revolver" },
    ['WEAPON_REVOLVER_DOUBLEACTION_GAMBLER'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "doubleaction_gambler_revolver" },
    ['WEAPON_REVOLVER_NAVY'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "navy_revolver" },
    ['WEAPON_REVOLVER_NAVY_CROSSOVER'] = { weaponGroup = "group_pistol", weaponSlot = "pistol", weaponDBName = "crossover_navy_revolver" },
    ['WEAPON_SHOTGUN_SAWEDOFF'] = { weaponGroup = "group_shotgun", weaponSlot = "pistol", weaponDBName = "sawedoff_shotgun" },

    -- Long Guns & Bows
    ['WEAPON_REPEATER_EVANS'] = { weaponGroup = "group_repeater", weaponSlot = "longgun", weaponDBName = "evans_repeater" },
    ['WEAPON_REPEATER_HENRY'] = { weaponGroup = "group_repeater", weaponSlot = "longgun", weaponDBName = "henry_repeater" },
    ['WEAPON_REPEATER_WINCHESTER'] = { weaponGroup = "group_repeater", weaponSlot = "longgun", weaponDBName = "winchester_repeater" },
    ['WEAPON_REPEATER_CARBINE'] = { weaponGroup = "group_repeater", weaponSlot = "longgun", weaponDBName = "carbine_repeater" },

    ['WEAPON_RIFLE_SPRINGFIELD'] = { weaponGroup = "group_rifle", weaponSlot = "longgun", weaponDBName = "springfield_rifle" },
    ['WEAPON_RIFLE_BOLTACTION'] = { weaponGroup = "group_rifle", weaponSlot = "longgun", weaponDBName = "boltaction_rifle" },
    ['WEAPON_RIFLE_VARMINT'] = { weaponGroup = "group_rifle", weaponSlot = "longgun", weaponDBName = "varmint_rifle" },
    ['WEAPON_RIFLE_ELEPHANT'] = { weaponGroup = "group_rifle", weaponSlot = "longgun", weaponDBName = "elephant_rifle" },

    ['WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun", weaponDBName = "exotic_doublebarrel_shotgun" },
    ['WEAPON_SHOTGUN_PUMP'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun", weaponDBName = "pump_shotgun" },
    ['WEAPON_SHOTGUN_REPEATING'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun", weaponDBName = "repeating_shotgun" },
    ['WEAPON_SHOTGUN_SEMIAUTO'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun", weaponDBName = "semiauto_shotgun" },
    ['WEAPON_SHOTGUN_DOUBLEBARREL'] = { weaponGroup = "group_shotgun", weaponSlot = "longgun", weaponDBName = "doublebarrel_shotgun" },

    ['WEAPON_SNIPERRIFLE_CARCANO'] = { weaponGroup = "group_sniper", weaponSlot = "longgun", weaponDBName = "carcano_sniper" },
    ['WEAPON_SNIPERRIFLE_ROLLINGBLOCK'] = { weaponGroup = "group_sniper", weaponSlot = "longgun", weaponDBName = "rollingblock_sniper" },

    ['WEAPON_BOW'] = { weaponGroup = "group_bow", weaponSlot = "longgun", weaponDBName = "bow" },
    ['WEAPON_BOW_IMPROVED'] = { weaponGroup = "group_bow", weaponSlot = "longgun", weaponDBName = "improved_bow" },

    -- Thrown
    ['WEAPON_MELEE_HATCHET'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "hatchet" },
    ['WEAPON_MELEE_HATCHET_HUNTER'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "hunter_hatchet" },
    ['WEAPON_THROWN_MOLOTOV'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "molotov" },
    ['WEAPON_THROWN_TOMAHAWK_ANCIENT'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "ancient_tomahawk" },
    ['WEAPON_THROWN_TOMAHAWK'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "tomahawk" },
    ['WEAPON_THROWN_DYNAMITE'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "dynamite" },
    ['WEAPON_MELEE_HATCHET_DOUBLE_BIT'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "double_bit_hatchet" },
    ['WEAPON_THROWN_THROWING_KNIVES'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "throwing_knives" },
    ['WEAPON_MELEE_CLEAVER'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "cleaver" },
    ['WEAPON_THROWN_BOLAS'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "bolas" },
    ['WEAPON_THROWN_POISONBOTTLE'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "poison_bottle" },
    ['WEAPON_THROWN_BOLAS_HAWKMOTH'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "hawkmoth_bolas" },
    ['WEAPON_THROWN_BOLAS_IRONSPIKED'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "ironspiked_bolas" },
    ['WEAPON_THROWN_BOLAS_INTERTWINED'] = { weaponGroup = "group_thrown", weaponSlot = "throwable", weaponDBName = "intertwined_bolas" },

    -- Held
    ['WEAPON_MELEE_DAVY_LANTERN'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "davy_lantern" },
    ['WEAPON_KIT_BINOCULARS'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "binoculars" },
    ['WEAPON_KIT_CAMERA'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "camera" },
    ['WEAPON_KIT_CAMERA_ADVANCED'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "advanced_camera" },
    ['WEAPON_KIT_BINOCULARS_IMPROVED'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "improved_binoculars" },
    ['WEAPON_KIT_METAL_DETECTOR'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "metal_detector" },
    ['WEAPON_MELEE_LANTERN_HALLOWEEN'] = { weaponGroup = "group_held", weaponSlot = "melee", weaponDBName = "halloween_lantern" },

    -- Fishing rod
    ['WEAPON_FISHINGROD'] = { weaponGroup = "group_fishingrod", weaponSlot = "melee", weaponDBName = "fishing_rod" },

    -- lasso
    ['WEAPON_LASSO'] = { weaponGroup = "group_lasso", weaponSlot = "melee", weaponDBName = "lasso" },
    ['WEAPON_LASSO_REINFORCED'] = { weaponGroup = "group_lasso", weaponSlot = "melee", weaponDBName = "reinforced_lasso" },

    -- Petrol Can
    ['WEAPON_MOONSHINEJUG_MP'] = { weaponGroup = "group_petrolcan", weaponSlot = "melee", weaponDBName = "moonshine_jug" }
}