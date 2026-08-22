WeaponAPI = {}

function WeaponAPI.GetCapabilities()
    return {
        contractVersion = WeaponConstants.ContractVersion,
        ready = DefinitionRegistry.IsReady(),
        definitions = DefinitionRegistry.Counts(),
        inventory = InventoryAdapter.GetCapabilities(),
        features = {
            definitions = true,
            metadataValidation = true,
            characterSessions = true,
            reconciliation = true,
            inventoryPersistence = InventoryAdapter.IsReady(),
            equipAuthorization = true,
            equip = InventoryAdapter.IsReady(),
            ammunition = InventoryAdapter.IsReady(),
            reload = InventoryAdapter.IsReady(),
            unload = false,
            fireCheckpoint = InventoryAdapter.IsReady(),
            condition = InventoryAdapter.IsReady(),
            repair = InventoryAdapter.IsReady()
        }
    }
end

function WeaponAPI.GetDefinition(kind, id)
    return DefinitionRegistry.Get(kind, id)
end

function WeaponAPI.ListDefinitions(kind)
    return DefinitionRegistry.List(kind)
end

function WeaponAPI.GetRuntime(source)
    return WeaponRuntime.Get(source)
end

exports("initiate", function()
    return {
        GetCapabilities = WeaponAPI.GetCapabilities,
        Definitions = { Get = WeaponAPI.GetDefinition, List = WeaponAPI.ListDefinitions },
        Metadata = { Build = WeaponMetadata.Build, Validate = WeaponMetadata.Validate },
        Runtime = { Get = WeaponAPI.GetRuntime },
        Inventory = {
            InstallProvider = InventoryAdapter.InstallProvider,
            GetCapabilities = InventoryAdapter.GetCapabilities
        }
    }
end)
