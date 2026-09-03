WeaponDefinitionCatalog = {
    ammunition = {
        revolver_standard = {
            id = "revolver_standard",
            kind = "ammunition",
            itemName = "revolver_standard",
            label = "Revolver Cartridges",
            nativeAmmoName = "AMMO_REVOLVER",
            stackable = true,
            tags = { "revolver", "standard" }
        }
    },
    weapons = {
        revolver_cattleman = {
            id = "revolver_cattleman",
            kind = "weapon",
            itemName = "revolver_cattleman",
            label = "Cattleman Revolver",
            nativeWeaponName = "WEAPON_REVOLVER_CATTLEMAN",
            family = "revolver",
            slot = "sidearm",
            ammunitionType = "revolver_standard",
            capacity = 6,
            condition = {
                minimum = 0,
                maximum = 100,
                equipMinimum = 1,
                wearPerShot = 1,
                repair = {
                    itemDefinitionId = "weapon_repair_kit",
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
            itemName = "revolver_schofield",
            label = "Schofield Revolver",
            nativeWeaponName = "WEAPON_REVOLVER_SCHOFIELD",
            family = "revolver",
            slot = "sidearm",
            ammunitionType = "revolver_standard",
            capacity = 6,
            condition = {
                minimum = 0,
                maximum = 100,
                equipMinimum = 1,
                wearPerShot = 1,
                repair = {
                    itemDefinitionId = "weapon_repair_kit",
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
        }
    },
    -- Each attachment defines: id, itemName, label, slot,
    -- nativeComponentName, conflicts, removable, and optional tags.
    attachments = {
        cattleman_long_barrel = {
            id = "cattleman_long_barrel",
            kind = "attachment",
            itemName = "cattleman_long_barrel",
            label = "Cattleman Long Barrel",
            slot = "barrel",
            nativeComponentName = "COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG",
            conflicts = {},
            removable = true,
            tags = { "functional", "cattleman" }
        }
    }
}
