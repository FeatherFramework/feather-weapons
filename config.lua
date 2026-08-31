Config = {
    DevMode = false,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 2,
        equipmentSlot = "weapon"
    },
    Runtime = {
        authorizationTtlMs = 5000,
        authoritativeNativeAmmo = true,
        observationIntervalMs = 50,
        checkpointDebounceMs = 250
    },
    Escrow = {
        -- Maximum cartridges authorized in one equipped native weapon pool.
        maxTotal = 30,
        -- Using compatible ammunition fills up to this boundary.
        refillAmount = 30
    },
    NativeProbe = {
        -- Isolated Phase 1 diagnostic. Enable only on a development server.
        enabled = false,
        weapon = "WEAPON_REVOLVER_CATTLEMAN",
        ammo = "AMMO_REVOLVER",
        capacity = 6,
        observationIntervalMs = 50
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
    }
}
