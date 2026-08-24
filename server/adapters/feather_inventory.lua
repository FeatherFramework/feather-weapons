local FeatherInventoryProvider = {}
local Inventory = nil
local DefinitionIds = {}
local MissingDefinitions = {}
local DuplicateDefinitions = {}

local function Failure(context, message, details)
    return WeaponResult.Error(WeaponErrors.INVENTORY_UNAVAILABLE, message, details,
        context and context.correlationId)
end

local function NormalizeItem(item)
    if type(item) ~= "table" then return nil end
    return {
        id = item.id,
        inventoryId = item.inventoryId,
        itemName = item.definition and item.definition.name or nil,
        metadata = item.metadata,
        metadataRevision = item.revision,
        definitionId = item.definition and item.definition.id or nil
    }
end

local function BuildDefinitionIndex()
    DefinitionIds = {}
    DuplicateDefinitions = {}
    local definitions = Inventory.Items.GetDefinitions()
    for _, definition in pairs(definitions or {}) do
        local name, id = definition.name, tonumber(definition.id)
        if name and id then
            local current = DefinitionIds[name]
            if current then
                DuplicateDefinitions[name] = DuplicateDefinitions[name] or { current }
                DuplicateDefinitions[name][#DuplicateDefinitions[name] + 1] = id
            end
            if not current or id < current then DefinitionIds[name] = id end
        end
    end

    for name, ids in pairs(DuplicateDefinitions) do
        table.sort(ids)
        print(("[feather-weapons] duplicate inventory definition name=%s ids=%s canonical=%s"):format(
            tostring(name), table.concat(ids, ","), tostring(DefinitionIds[name])))
    end

    MissingDefinitions = {}
    local required = { cattleman_revolver = true, revolver_standard = true, weapon_repair_kit = true }
    for name in pairs(required) do
        if not DefinitionIds[name] then MissingDefinitions[#MissingDefinitions + 1] = name end
    end
    table.sort(MissingDefinitions)
end

function FeatherInventoryProvider.GetCapabilities()
    local capabilities = Inventory and Inventory.GetCapabilities and Inventory.GetCapabilities() or {}
    return {
        contractVersion = Config.Inventory.requiredContract,
        provider = "feather-inventory",
        inventoryVersion = capabilities.version,
        features = capabilities.features,
        uniqueItems = capabilities.features and capabilities.features.instanceMode == true,
        equippedState = capabilities.features and capabilities.features.equippedState == true,
        reconnectPersistence = true,
        resourceRestartPersistence = true,
        transactions = capabilities.features and capabilities.features.transactions == true,
        atomicCreation = capabilities.features and capabilities.features.atomicCreation == true,
        missingDefinitions = MissingDefinitions,
        duplicateDefinitions = DuplicateDefinitions
    }
end

function FeatherInventoryProvider.GetItemForCharacter(context, itemInstanceId)
    local result = Inventory.GetItemForCharacter(context.characterId, itemInstanceId)
    if not result.ok then return result end
    return WeaponResult.Ok(NormalizeItem(result.value), context.correlationId)
end

function FeatherInventoryProvider.GetEquippedForCharacter(context)
    local result = Inventory.GetEquippedForCharacter(context.characterId, Config.Inventory.equipmentSlot)
    if not result.ok then return result end
    return WeaponResult.Ok(result.value, context.correlationId)
end

function FeatherInventoryProvider.SetEquippedForCharacter(context, itemInstanceId)
    local result = Inventory.SetEquippedForCharacter(context.characterId, Config.Inventory.equipmentSlot, itemInstanceId)
    if not result.ok then return result end
    return WeaponResult.Ok(itemInstanceId, context.correlationId)
end

function FeatherInventoryProvider.CreateWeapon(context, definition, metadata)
    local definitionId = DefinitionIds[definition.itemName]
    if not definitionId then
        return Failure(context, "Weapon inventory definition is missing", { itemName = definition.itemName })
    end
    local result = Inventory.CreateInstance(context, {
        characterId = context.characterId,
        definitionId = definitionId,
        metadata = metadata
    })
    if not result.ok then return result end
    return WeaponResult.Ok(result.value, context.correlationId)
end

function FeatherInventoryProvider.Transaction(context, callback)
    local currentItem = nil
    local quantities = {}
    local quantityInstanceIds = {}
    local removals = {}
    local additions = {}
    local nextMetadata = nil
    local expectedRevision = nil
    local tx = {}

    function tx:GetItemForUpdate(itemInstanceId)
        local result = Inventory.GetItemForCharacter(context.characterId, itemInstanceId)
        if not result.ok then return nil end
        currentItem = NormalizeItem(result.value)
        return currentItem
    end

    function tx:GetQuantity(definitionName)
        if not currentItem then return 0 end
        if quantities[definitionName] == nil then
            local found = Inventory.Instances.FindInstances(currentItem.inventoryId, definitionName)
            quantityInstanceIds[definitionName] = found.ok and found.value or {}
            quantities[definitionName] = #quantityInstanceIds[definitionName]
        end
        return quantities[definitionName]
    end

    function tx:RemoveQuantity(definitionName, quantity)
        local catalogDefinitionId = DefinitionIds[definitionName]
        local wanted = math.floor(tonumber(quantity) or 0)
        local available = self:GetQuantity(definitionName)
        local ids = quantityInstanceIds[definitionName] or {}
        local first = ids[1] and Inventory.Instances.GetInstance(ids[1]) or nil
        local firstValue = first and first.ok and first.value or nil
        local definitionId = firstValue and firstValue.definition and tonumber(firstValue.definition.id)
            or catalogDefinitionId
        if Config.DevMode then
            print(("[feather-weapons] inventory removal planned inventory=%s actualInventory=%s item=%s definition=%s catalogDefinition=%s available=%s requested=%s firstInstance=%s"):format(
                tostring(currentItem and currentItem.inventoryId), tostring(firstValue and firstValue.inventoryId),
                tostring(definitionName), tostring(definitionId), tostring(catalogDefinitionId),
                tostring(available), tostring(wanted), tostring(ids[1])))
        end
        if not definitionId or wanted < 1 or available < wanted then return false end
        local selected = {}
        for index = 1, wanted do
            local id = table.remove(ids, 1)
            local instance = id and Inventory.Instances.GetInstance(id) or nil
            local value = instance and instance.ok and instance.value or nil
            if not value or tostring(value.inventoryId) ~= tostring(currentItem.inventoryId)
                or not value.definition or tonumber(value.definition.id) ~= tonumber(definitionId) then
                return false
            end
            selected[index] = id
        end
        quantities[definitionName] = #ids
        removals[definitionId] = removals[definitionId] or { quantity = 0, instanceIds = {} }
        removals[definitionId].quantity = removals[definitionId].quantity + wanted
        for _, id in ipairs(selected) do
            removals[definitionId].instanceIds[#removals[definitionId].instanceIds + 1] = id
        end
        return true
    end

    function tx:AddQuantity(definitionName, quantity, metadata)
        local definitionId = DefinitionIds[definitionName]
        local wanted = math.floor(tonumber(quantity) or 0)
        if not definitionId or wanted < 1 then return false end
        local available = self:GetQuantity(definitionName)
        quantities[definitionName] = available + wanted
        additions[definitionId] = additions[definitionId] or { quantity = 0, metadata = metadata }
        additions[definitionId].quantity = additions[definitionId].quantity + wanted
        return true
    end

    function tx:SetMetadata(itemInstanceId, metadata, revision)
        if not currentItem or tostring(currentItem.id) ~= tostring(itemInstanceId)
            or tonumber(currentItem.metadataRevision) ~= tonumber(revision) then
            return false
        end
        nextMetadata = metadata
        expectedRevision = revision
        return true
    end

    local ok, outcome = pcall(callback, tx)
    if not ok then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapons inventory calculation failed", {
            reason = tostring(outcome)
        }, context.correlationId)
    end
    if type(outcome) == "table" and outcome.ok == false then return outcome end

    if nextMetadata ~= nil or next(removals) ~= nil or next(additions) ~= nil then
        if not currentItem then
            return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Weapon item is unavailable", nil,
                context.correlationId)
        end
        local removalList = {}
        for definitionId, removal in pairs(removals) do
            removalList[#removalList + 1] = {
                definitionId = definitionId,
                quantity = removal.quantity,
                instanceIds = removal.instanceIds
            }
        end
        local additionList = {}
        for definitionId, addition in pairs(additions) do
            additionList[#additionList + 1] = {
                definitionId = definitionId,
                quantity = addition.quantity,
                metadata = addition.metadata
            }
        end
        local committed = Inventory.MutateItem(context, {
            itemInstanceId = currentItem.id,
            expectedRevision = expectedRevision or currentItem.metadataRevision,
            metadata = nextMetadata,
            removals = removalList,
            additions = additionList
        })
        if not committed.ok then
            if Config.DevMode then
                local failure = committed.error or {}
                print(("[feather-weapons] inventory mutation failed inventory=%s code=%s message=%s details=%s"):format(
                    tostring(currentItem.inventoryId), tostring(failure.code), tostring(failure.message),
                    json.encode(failure.details or {})))
            end
            return committed
        end
    end

    return WeaponResult.Ok(outcome, context.correlationId)
end
local function RegisterUsableWeapons()
    local listed = DefinitionRegistry.List("weapon")
    if not listed.ok then return end
    for _, definition in ipairs(listed.value) do
        if DefinitionIds[definition.itemName] then
            Inventory.Items.RegisterUsableItem(definition.itemName, function(item, source, done)
                if Config.DevMode then
                    print(("[feather-weapons] inventory use item=%s source=%s")
                        :format(tostring(item.id), tostring(source)))
                end
                TriggerClientEvent("feather-weapons:client:useInventoryWeapon", source, item.id)
                if done then done() end
            end)
        end
    end
end

local function RegisterUsableRepairItems()
    local listed = DefinitionRegistry.List("weapon")
    if not listed.ok then return end
    local registered = {}
    for _, definition in ipairs(listed.value) do
        local repair = definition.condition and definition.condition.repair
        local itemName = repair and repair.itemDefinitionId
        if itemName and DefinitionIds[itemName] and not registered[itemName] then
            registered[itemName] = true
            Inventory.Items.RegisterUsableItem(itemName, function(item, source, done)
                if Config.DevMode then
                    print(("[feather-weapons] inventory repair use item=%s source=%s")
                        :format(tostring(item.id), tostring(source)))
                end
                local runtime = WeaponRuntime.Get(source)
                local result
                if not runtime or not runtime.equipped then
                    result = WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "Equip a weapon before using a repair kit")
                else
                    local rpcContext = {
                        characterId = runtime.characterId,
                        sessionId = runtime.sessionId,
                        correlationId = ("inventory-repair:%s:%s"):format(tostring(source), tostring(GetGameTimer()))
                    }
                    result = RepairService.Repair(source, rpcContext, runtime.equipped.itemInstanceId)
                end
                TriggerClientEvent("feather-weapons:client:inventoryRepairResult", source, result)
                if done then done() end
            end)
        end
    end
end

local function RegisterGuards()
    local function EquippedGuard(instance)
        if Inventory.Equipment.IsInstanceEquipped(instance.id) then
            return false, "Unequip this item before moving or removing it."
        end
        return true
    end

    Inventory.Guards.RegisterMoveGuard("feather-weapons", EquippedGuard)
    Inventory.Guards.RegisterDestroyGuard("feather-weapons", EquippedGuard)
end

function InstallFeatherInventoryProvider()
    if GetResourceState("feather-inventory") ~= "started" then
        return Failure(nil, "feather-inventory is not started")
    end

    local ok, api = pcall(function() return exports["feather-inventory"].initiate() end)
    if not ok or type(api) ~= "table" then
        return Failure(nil, "feather-inventory API is unavailable", { reason = tostring(api) })
    end

    local required = { "Items", "Instances", "Equipment", "Guards", "Transaction", "MutateItem", "CreateInstance", "GetCapabilities",
        "GetItemForCharacter", "GetEquippedForCharacter", "SetEquippedForCharacter" }
    for _, name in ipairs(required) do
        if api[name] == nil then
            return Failure(nil, "feather-inventory is missing a required API", { operation = name })
        end
    end

    Inventory = api
    BuildDefinitionIndex()
    RegisterUsableWeapons()
    RegisterUsableRepairItems()
    RegisterGuards()
    return InventoryAdapter.InstallProvider(FeatherInventoryProvider)
end