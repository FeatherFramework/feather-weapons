Config = {
    DevMode = true,
    StrictStartup = true,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 2,
        equipmentSlot = "weapon"
    },
    Runtime = {
        authorizationTtlMs = 5000,
        authoritativeNativeAmmo = true
    },
    Attachments = {
        requireStation = true,
        interactionDistance = 2.0,
        serverTolerance = 3.0,
        stations = {
            valentine = {
                label = "Valentine Gunsmith Bench",
                coords = vector3(-277.455, 779.197, 119.504)
            }
        }
    },
    Controls = {
        reload = {
            enabled = true,
            defaultKey = "R",
            command = "feather_weapon_reload",
            nativeControl = 0xE30CD707,
            disableNative = true
        },
        unload = {
            enabled = true,
            defaultKey = "U",
            command = "feather_weapon_unload"
        },
        modify = {
            enabled = true,
            defaultKey = "F6",
            command = "weaponmods"
        }
    },
    Logging = {
        level = "info"
    }
}
