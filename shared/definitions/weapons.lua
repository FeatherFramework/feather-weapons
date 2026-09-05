WeaponDefinitionCatalog = WeaponDefinitionCatalog or {}

WeaponDefinitionCatalog.weapons = {
    pistol_volcanic = {
        id = "pistol_volcanic",
        kind = "weapon",
        itemName = "weapon_pistol_volcanic",
        label = "Volcanic Pistol",
        nativeWeaponName = "WEAPON_PISTOL_VOLCANIC",
        family = "pistol",
        slot = "sidearm",
        ammunitionType = "ammo_pistol_regular",
        ammunitionTypes = { "ammo_pistol_regular", "ammo_pistol_express", "ammo_pistol_high_velocity", "ammo_pistol_split_point", "ammo_pistol_explosive" },
        capacity = 8,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "pistol" }
    },
    pistol_m1899 = {
        id = "pistol_m1899",
        kind = "weapon",
        itemName = "weapon_pistol_m1899",
        label = "M1899 Pistol",
        nativeWeaponName = "WEAPON_PISTOL_M1899",
        family = "pistol",
        slot = "sidearm",
        ammunitionType = "ammo_pistol_regular",
        ammunitionTypes = { "ammo_pistol_regular", "ammo_pistol_express", "ammo_pistol_high_velocity", "ammo_pistol_split_point", "ammo_pistol_explosive" },
        capacity = 8,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "pistol" }
    },
    pistol_semiauto = {
        id = "pistol_semiauto",
        kind = "weapon",
        itemName = "weapon_pistol_semiauto",
        label = "Semi-Automatic Pistol",
        nativeWeaponName = "WEAPON_PISTOL_SEMIAUTO",
        family = "pistol",
        slot = "sidearm",
        ammunitionType = "ammo_pistol_regular",
        ammunitionTypes = { "ammo_pistol_regular", "ammo_pistol_express", "ammo_pistol_high_velocity", "ammo_pistol_split_point", "ammo_pistol_explosive" },
        capacity = 8,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "pistol" }
    },
    pistol_mauser = {
        id = "pistol_mauser",
        kind = "weapon",
        itemName = "weapon_pistol_mauser",
        label = "Mauser Pistol",
        nativeWeaponName = "WEAPON_PISTOL_MAUSER",
        family = "pistol",
        slot = "sidearm",
        ammunitionType = "ammo_pistol_regular",
        ammunitionTypes = { "ammo_pistol_regular", "ammo_pistol_express", "ammo_pistol_high_velocity", "ammo_pistol_split_point", "ammo_pistol_explosive" },
        capacity = 10,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "pistol" }
    },

    revolver_cattleman = {
        id = "revolver_cattleman",
        kind = "weapon",
        itemName = "weapon_revolver_cattleman",
        label = "Cattleman Revolver",
        nativeWeaponName = "WEAPON_REVOLVER_CATTLEMAN",
        family = "revolver",
        slot = "sidearm",
        ammunitionType = "ammo_revolver_regular",
        ammunitionTypes = { "ammo_revolver_regular", "ammo_revolver_express", "ammo_revolver_high_velocity", "ammo_revolver_split_point", "ammo_revolver_explosive" },
        capacity = 6,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        -- Slot keys point to attachment definition IDs accepted by this weapon.
        attachmentSlots = {
            barrel = { "cattleman_long_barrel" }
        },
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "revolver" }
    },
    revolver_schofield = {
        id = "revolver_schofield",
        kind = "weapon",
        itemName = "weapon_revolver_schofield",
        label = "Schofield Revolver",
        nativeWeaponName = "WEAPON_REVOLVER_SCHOFIELD",
        family = "revolver",
        slot = "sidearm",
        ammunitionType = "ammo_revolver_regular",
        ammunitionTypes = { "ammo_revolver_regular", "ammo_revolver_express", "ammo_revolver_high_velocity", "ammo_revolver_split_point", "ammo_revolver_explosive" },
        capacity = 6,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "revolver" }
    },
    revolver_doubleaction = {
        id = "revolver_doubleaction",
        kind = "weapon",
        itemName = "weapon_revolver_doubleaction",
        label = "Double-Action Revolver",
        nativeWeaponName = "WEAPON_REVOLVER_DOUBLEACTION",
        family = "revolver",
        slot = "sidearm",
        ammunitionType = "ammo_revolver_regular",
        ammunitionTypes = { "ammo_revolver_regular", "ammo_revolver_express", "ammo_revolver_high_velocity", "ammo_revolver_split_point", "ammo_revolver_explosive" },
        capacity = 6,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "revolver" }
    },
    revolver_lemat = {
        id = "revolver_lemat",
        kind = "weapon",
        itemName = "weapon_revolver_lemat",
        label = "LeMat Revolver",
        nativeWeaponName = "WEAPON_REVOLVER_LEMAT",
        family = "revolver",
        slot = "sidearm",
        ammunitionType = "ammo_revolver_regular",
        ammunitionTypes = { "ammo_revolver_regular", "ammo_revolver_express", "ammo_revolver_high_velocity", "ammo_revolver_split_point", "ammo_revolver_explosive" },
        capacity = 9,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "revolver" }
    },
    revolver_navy = {
        id = "revolver_navy",
        kind = "weapon",
        itemName = "weapon_revolver_navy",
        label = "Navy Revolver",
        nativeWeaponName = "WEAPON_REVOLVER_NAVY",
        family = "revolver",
        slot = "sidearm",
        ammunitionType = "ammo_revolver_regular",
        ammunitionTypes = { "ammo_revolver_regular", "ammo_revolver_express", "ammo_revolver_high_velocity", "ammo_revolver_split_point", "ammo_revolver_explosive" },
        capacity = 6,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "revolver" }
    },

    repeater_carbine = {
        id = "repeater_carbine",
        kind = "weapon",
        itemName = "weapon_repeater_carbine",
        label = "Carbine Repeater",
        nativeWeaponName = "WEAPON_REPEATER_CARBINE",
        family = "repeater",
        slot = "longgun",
        ammunitionType = "ammo_repeater_regular",
        ammunitionTypes = { "ammo_repeater_regular", "ammo_repeater_express", "ammo_repeater_high_velocity", "ammo_repeater_split_point", "ammo_repeater_explosive" },
        capacity = 7,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "repeater" }
    },
    repeater_lancaster = {
        id = "repeater_lancaster",
        kind = "weapon",
        itemName = "weapon_repeater_lancaster",
        label = "Lancaster Repeater",
        nativeWeaponName = "WEAPON_REPEATER_WINCHESTER",
        family = "repeater",
        slot = "longgun",
        ammunitionType = "ammo_repeater_regular",
        ammunitionTypes = { "ammo_repeater_regular", "ammo_repeater_express", "ammo_repeater_high_velocity", "ammo_repeater_split_point", "ammo_repeater_explosive" },
        capacity = 14,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "repeater" }
    },
    repeater_henry = {
        id = "repeater_henry",
        kind = "weapon",
        itemName = "weapon_repeater_henry",
        label = "Litchfield Repeater",
        nativeWeaponName = "WEAPON_REPEATER_HENRY",
        family = "repeater",
        slot = "longgun",
        ammunitionType = "ammo_repeater_regular",
        ammunitionTypes = { "ammo_repeater_regular", "ammo_repeater_express", "ammo_repeater_high_velocity", "ammo_repeater_split_point", "ammo_repeater_explosive" },
        capacity = 16,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "repeater" }
    },
    repeater_evans = {
        id = "repeater_evans",
        kind = "weapon",
        itemName = "weapon_repeater_evans",
        label = "Evans Repeater",
        nativeWeaponName = "WEAPON_REPEATER_EVANS",
        family = "repeater",
        slot = "longgun",
        ammunitionType = "ammo_repeater_regular",
        ammunitionTypes = { "ammo_repeater_regular", "ammo_repeater_express", "ammo_repeater_high_velocity", "ammo_repeater_split_point", "ammo_repeater_explosive" },
        capacity = 26,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "repeater" }
    },

    rifle_springfield = {
        id = "rifle_springfield",
        kind = "weapon",
        itemName = "weapon_rifle_springfield",
        label = "Springfield Rifle",
        nativeWeaponName = "WEAPON_RIFLE_SPRINGFIELD",
        family = "rifle",
        slot = "longgun",
        ammunitionType = "ammo_rifle_regular",
        ammunitionTypes = { "ammo_rifle_regular", "ammo_rifle_express", "ammo_rifle_high_velocity", "ammo_rifle_split_point", "ammo_rifle_explosive" },
        capacity = 1,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "rifle" }
    },
    rifle_boltaction = {
        id = "rifle_boltaction",
        kind = "weapon",
        itemName = "weapon_rifle_boltaction",
        label = "Bolt Action Rifle",
        nativeWeaponName = "WEAPON_RIFLE_BOLTACTION",
        family = "rifle",
        slot = "longgun",
        ammunitionType = "ammo_rifle_regular",
        ammunitionTypes = { "ammo_rifle_regular", "ammo_rifle_express", "ammo_rifle_high_velocity", "ammo_rifle_split_point", "ammo_rifle_explosive" },
        capacity = 5,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "rifle" }
    },
    rifle_varmint = {
        id = "rifle_varmint",
        kind = "weapon",
        itemName = "weapon_rifle_varmint",
        label = "Varmint Rifle",
        nativeWeaponName = "WEAPON_RIFLE_VARMINT",
        family = "rifle",
        slot = "longgun",
        ammunitionType = "ammo_varmint",
        ammunitionTypes = { "ammo_varmint", "ammo_varmint_tranquilizer" },
        capacity = 14,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "rifle" }
    },
    rifle_rollingblock = {
        id = "rifle_rollingblock",
        kind = "weapon",
        itemName = "weapon_sniperrifle_rollingblock",
        label = "Rolling Block Rifle",
        nativeWeaponName = "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
        family = "rifle",
        slot = "longgun",
        ammunitionType = "ammo_rifle_regular",
        ammunitionTypes = { "ammo_rifle_regular", "ammo_rifle_express", "ammo_rifle_high_velocity", "ammo_rifle_split_point", "ammo_rifle_explosive" },
        capacity = 1,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "rifle" }
    },
    rifle_carcano = {
        id = "rifle_carcano",
        kind = "weapon",
        itemName = "weapon_sniperrifle_carcano",
        label = "Carcano Rifle",
        nativeWeaponName = "WEAPON_SNIPERRIFLE_CARCANO",
        family = "rifle",
        slot = "longgun",
        ammunitionType = "ammo_rifle_regular",
        ammunitionTypes = { "ammo_rifle_regular", "ammo_rifle_express", "ammo_rifle_high_velocity", "ammo_rifle_split_point", "ammo_rifle_explosive" },
        capacity = 6,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "rifle" }
    },
    rifle_elephant = {
        id = "rifle_elephant",
        kind = "weapon",
        itemName = "weapon_rifle_elephant",
        label = "Elephant Rifle",
        nativeWeaponName = "WEAPON_RIFLE_ELEPHANT",
        family = "rifle",
        slot = "longgun",
        ammunitionType = "ammo_rifle_elephant",
        ammunitionTypes = { "ammo_rifle_elephant" },
        capacity = 2,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "rifle" }
    },

    shotgun_doublebarrel = {
        id = "shotgun_doublebarrel",
        kind = "weapon",
        itemName = "weapon_shotgun_doublebarrel",
        label = "Double-Barreled Shotgun",
        nativeWeaponName = "WEAPON_SHOTGUN_DOUBLEBARREL",
        family = "shotgun",
        slot = "longgun",
        ammunitionType = "ammo_shotgun_regular",
        ammunitionTypes = { "ammo_shotgun_regular", "ammo_shotgun_slug", "ammo_shotgun_buckshot_incendiary", "ammo_shotgun_slug_explosive" },
        capacity = 2,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "shotgun" }
    },
    shotgun_sawedoff = {
        id = "shotgun_sawedoff",
        kind = "weapon",
        itemName = "weapon_shotgun_sawedoff",
        label = "Sawed-Off Shotgun",
        nativeWeaponName = "WEAPON_SHOTGUN_SAWEDOFF",
        family = "shotgun",
        slot = "sidearm",
        ammunitionType = "ammo_shotgun_regular",
        ammunitionTypes = { "ammo_shotgun_regular", "ammo_shotgun_slug", "ammo_shotgun_buckshot_incendiary", "ammo_shotgun_slug_explosive" },
        capacity = 2,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "sidearm", "shotgun" }
    },
    shotgun_pump = {
        id = "shotgun_pump",
        kind = "weapon",
        itemName = "weapon_shotgun_pump",
        label = "Pump-Action Shotgun",
        nativeWeaponName = "WEAPON_SHOTGUN_PUMP",
        family = "shotgun",
        slot = "longgun",
        ammunitionType = "ammo_shotgun_regular",
        ammunitionTypes = { "ammo_shotgun_regular", "ammo_shotgun_slug", "ammo_shotgun_buckshot_incendiary", "ammo_shotgun_slug_explosive" },
        capacity = 5,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "shotgun" }
    },
    shotgun_semiauto = {
        id = "shotgun_semiauto",
        kind = "weapon",
        itemName = "weapon_shotgun_semiauto",
        label = "Semi-Auto Shotgun",
        nativeWeaponName = "WEAPON_SHOTGUN_SEMIAUTO",
        family = "shotgun",
        slot = "longgun",
        ammunitionType = "ammo_shotgun_regular",
        ammunitionTypes = { "ammo_shotgun_regular", "ammo_shotgun_slug", "ammo_shotgun_buckshot_incendiary", "ammo_shotgun_slug_explosive" },
        capacity = 5,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "shotgun" }
    },
    shotgun_repeating = {
        id = "shotgun_repeating",
        kind = "weapon",
        itemName = "weapon_shotgun_repeating",
        label = "Repeating Shotgun",
        nativeWeaponName = "WEAPON_SHOTGUN_REPEATING",
        family = "shotgun",
        slot = "longgun",
        ammunitionType = "ammo_shotgun_regular",
        ammunitionTypes = { "ammo_shotgun_regular", "ammo_shotgun_slug", "ammo_shotgun_buckshot_incendiary", "ammo_shotgun_slug_explosive" },
        capacity = 6,
        condition = {
            minimum = 0,
            maximum = 100,
            equipMinimum = 1,
            wearPerShot = 1,
            repair = {
                itemDefinitionId = "gun_oil",
                quantity = 1,
                restore = 25
            }
        },
        attachmentSlots = {},
        policies = {
            transferable = true,
            droppable = true,
            destructible = true,
            serialRequired = true
        },
        tags = { "firearm", "longgun", "shotgun" }
    }
}
