WeaponDefinitionCatalog = {
    ammunition = {
        revolver_standard = {
            id = "revolver_standard",
            kind = "ammunition",
            itemName = "ammo_revolver",
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
            itemName = "cattleman_revolver",
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
                wearPerShot = 1
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
    attachments = {}
}
