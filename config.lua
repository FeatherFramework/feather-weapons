Config = {
    DevMode = false,
    RequiredCoreContract = 1,
    Inventory = {
        requiredContract = 4,
        -- Stable Inventory equipment keys. Do not rename these after launch.
        equipmentSlot = "weapon", -- Legacy alias for the primary slot.
        equipmentSlots = {
            primary = "weapon",
            offhand = "weapon_offhand"
        }
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
    Offhand = {
        -- Disable to run this server in primary-weapon-only mode.
        enabled = true,
        -- Only definition families/slots set to true may use the offhand.
        allowedFamilies = { revolver = true },
        allowedWeaponSlots = { sidearm = true },
        -- Automatically provide RedM's offhand holster entitlement when needed.
        provisionNativeEntitlement = true,
        -- RedM requires both an offhand clothing entitlement and its upgrade.
        -- Tested tint variants did not visibly restyle the equipped holster.
        nativeEntitlements = {
            { itemName = "CLOTHING_ITEM_M_OFFHAND_000_TINT_001", slotId = 0xF20B6B4A },
            { itemName = "UPGRADE_OFFHAND_HOLSTER", slotId = 0x39E57B01 }
        },
        -- Native holster points; change only for a tested clothing setup.
        primaryAttachPoint = 2,
        offhandAttachPoint = 3
    },
    NativeProbe = {
        -- Isolated Phase 1 diagnostic. Enable only on a development server.
        enabled = false,
        weapon = "WEAPON_REVOLVER_CATTLEMAN",
        -- Second native used only by the Phase 7 offhand/dual-wield probe.
        offhandWeapon = "WEAPON_REVOLVER_SCHOFIELD",
        ammo = "AMMO_REVOLVER",
        capacity = 6,
        primaryAttachPoint = 2,
        offhandAttachPoint = 3,
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
