local TestInventoryProvider = {}
local characters = {}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function EnsureCharacter(context)
    local key = tostring(context.characterId)
    if characters[key] then return characters[key] end

    local definitionResult = DefinitionRegistry.Get("weapon", "revolver_cattleman")
    if not definitionResult.ok then return nil, definitionResult end
    local metadataResult = WeaponMetadata.Build(definitionResult.value, {
        serialNumber = "DEV-" .. key
    })
    if not metadataResult.ok then return nil, metadataResult end

    characters[key] = {
        equipped = nil,
        quantities = { revolver_standard = 24, weapon_repair_kit = 3 },
        item = {
            id = "dev:cattleman:" .. key,
            inventoryId = "development",
            itemName = "cattleman_revolver",
            metadataRevision = 1,
            metadata = metadataResult.value
        }
    }
    return characters[key]
end

function TestInventoryProvider.GetCapabilities()
    return {
        contractVersion = Config.Inventory.requiredContract,
        provider = "development-memory",
        uniqueItems = true,
        equippedState = true,
        reconnectPersistence = true,
        resourceRestartPersistence = false,
        transactions = true
    }
end

function TestInventoryProvider.GetItemForCharacter(context, itemInstanceId)
    local state, failure = EnsureCharacter(context)
    if not state then return failure end
    if itemInstanceId ~= state.item.id then
        return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Development weapon item is not owned by this character", {
            itemInstanceId = itemInstanceId
        }, context.correlationId)
    end
    return WeaponResult.Ok(Copy(state.item), context.correlationId)
end

function TestInventoryProvider.GetEquippedForCharacter(context)
    local state, failure = EnsureCharacter(context)
    if not state then return failure end
    return WeaponResult.Ok(state.equipped, context.correlationId)
end

function TestInventoryProvider.SetEquippedForCharacter(context, itemInstanceId)
    local state, failure = EnsureCharacter(context)
    if not state then return failure end
    if itemInstanceId ~= nil and itemInstanceId ~= state.item.id then
        return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Development weapon item is not owned by this character", nil, context.correlationId)
    end
    state.equipped = itemInstanceId
    return WeaponResult.Ok(itemInstanceId, context.correlationId)
end

function TestInventoryProvider.Transaction(context, callback)
    local state, failure = EnsureCharacter(context)
    if not state then return failure end
    local working = Copy(state)
    local tx = {}

    function tx:GetItemForUpdate(itemInstanceId)
        if itemInstanceId ~= working.item.id then return nil end
        return Copy(working.item)
    end

    function tx:GetQuantity(definitionId)
        return tonumber(working.quantities[definitionId]) or 0
    end

    function tx:RemoveQuantity(definitionId, quantity)
        local current = self:GetQuantity(definitionId)
        if quantity < 0 or current < quantity then return false end
        working.quantities[definitionId] = current - quantity
        return true
    end

    function tx:AddQuantity(definitionId, quantity)
        if quantity < 0 then return false end
        working.quantities[definitionId] = self:GetQuantity(definitionId) + quantity
        return true
    end

    function tx:SetMetadata(itemInstanceId, metadata, expectedRevision)
        if itemInstanceId ~= working.item.id or working.item.metadataRevision ~= expectedRevision then return false end
        working.item.metadata = Copy(metadata)
        working.item.metadataRevision = working.item.metadataRevision + 1
        return true
    end

    local ok, result = pcall(callback, tx)
    if not ok then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Development inventory transaction failed", {
            reason = tostring(result)
        }, context.correlationId)
    end
    if type(result) == "table" and result.ok == false then return result end
    characters[tostring(context.characterId)] = working
    return WeaponResult.Ok(result, context.correlationId)
end

function InstallTestInventoryProvider()
    if not Config.DevMode or not Config.Inventory.allowTestAdapter then return nil end
    return InventoryAdapter.InstallProvider(TestInventoryProvider)
end
