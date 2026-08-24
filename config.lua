Config = {
    DevMode = true,
    StrictStartup = true,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 1,
        equipmentSlot = "weapon"
    },
    Runtime = {
        authorizationTtlMs = 5000,
        authoritativeNativeAmmo = true
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
        }
    },
    Logging = {
        level = "info"
    }
}
