InventoryAdapter = {}
local provider = nil

local function Unavailable(context, operation)
    return WeaponResult.Error(WeaponErrors.INVENTORY_UNAVAILABLE,
        "Inventory provider does not support " .. operation, nil, context and context.correlationId)
end

function InventoryAdapter.InstallProvider(candidate)
    if type(candidate) ~= "table" or type(candidate.GetCapabilities) ~= "function" then
        return WeaponResult.Error(WeaponErrors.INVENTORY_UNAVAILABLE, "Inventory provider is invalid")
    end

    local capabilities = candidate.GetCapabilities()
    local contractVersion = capabilities and tonumber(capabilities.contractVersion) or 0
    if contractVersion < Config.Inventory.requiredContract then
        return WeaponResult.Error(WeaponErrors.INVENTORY_UNAVAILABLE, "Inventory contract is too old", {
            required = Config.Inventory.requiredContract,
            actual = capabilities and capabilities.contractVersion or nil
        })
    end
    if type(candidate.GetItemForCharacter) ~= "function"
        or type(candidate.GetEquippedForCharacter) ~= "function"
        or type(candidate.SetEquippedForCharacter) ~= "function"
        or type(candidate.Transaction) ~= "function" then
        return WeaponResult.Error(WeaponErrors.INVENTORY_UNAVAILABLE, "Inventory provider is missing required operations")
    end

    provider = candidate
    return WeaponResult.Ok(capabilities)
end

function InventoryAdapter.IsReady()
    return provider ~= nil
end

function InventoryAdapter.GetCapabilities()
    if not provider then return { contractVersion = 0, ready = false, reason = "provider_not_installed" } end
    local capabilities = provider.GetCapabilities()
    capabilities.ready = true
    return capabilities
end

function InventoryAdapter.GetItemForCharacter(context, itemInstanceId)
    if not provider then return Unavailable(context, "GetItemForCharacter") end
    return provider.GetItemForCharacter(context, itemInstanceId)
end

function InventoryAdapter.GetEquippedForCharacter(context)
    if not provider then return Unavailable(context, "GetEquippedForCharacter") end
    return provider.GetEquippedForCharacter(context)
end

function InventoryAdapter.SetEquippedForCharacter(context, itemInstanceId)
    if not provider then return Unavailable(context, "SetEquippedForCharacter") end
    return provider.SetEquippedForCharacter(context, itemInstanceId)
end

function InventoryAdapter.Transaction(context, callback)
    if not provider then return Unavailable(context, "Transaction") end
    return provider.Transaction(context, callback)
end
