EquipService = {}

local function BuildContext(source, session, correlationId, reason)
    return {
        actorSource = source,
        actorCharacterId = session.characterId,
        characterId = session.characterId,
        sessionId = session.sessionId,
        correlationId = correlationId,
        reason = reason,
        resource = "feather-weapons"
    }
end

function EquipService.ValidateOwnedItem(context, itemInstanceId)
    if type(itemInstanceId) ~= "string" or itemInstanceId == "" or #itemInstanceId > 128 then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Item instance ID is invalid", nil, context.correlationId)
    end

    local itemResult = InventoryAdapter.GetItemForCharacter(context, itemInstanceId)
    if not itemResult.ok then return itemResult end
    local item = itemResult.value
    local metadata = type(item.metadata) == "table" and item.metadata or nil
    if not metadata or type(metadata.weaponDefinitionId) ~= "string" then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Weapon item metadata is invalid", {
            itemInstanceId = itemInstanceId
        }, context.correlationId)
    end

    local definitionResult = DefinitionRegistry.Get("weapon", metadata.weaponDefinitionId)
    if not definitionResult.ok then return definitionResult end
    local definition = definitionResult.value
    if item.itemName ~= definition.itemName then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Item definition does not match weapon metadata", {
            itemName = item.itemName,
            expectedItemName = definition.itemName
        }, context.correlationId)
    end

    local metadataResult = WeaponMetadata.Validate(metadata, definition, context.correlationId)
    if not metadataResult.ok then return metadataResult end
    if metadata.flags.disabled or metadata.flags.evidence then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Weapon item is disabled", {
            itemInstanceId = itemInstanceId
        }, context.correlationId)
    end
    if tonumber(metadata.condition) < definition.condition.equipMinimum then
        return WeaponResult.Error(WeaponErrors.CONDITION_BROKEN, "Weapon condition is too low to equip", {
            condition = metadata.condition,
            minimum = definition.condition.equipMinimum
        }, context.correlationId)
    end
    return WeaponResult.Ok({ item = item, definition = definition }, context.correlationId)
end

function EquipService.Request(source, rpcContext, itemInstanceId)
    local context = BuildContext(source, rpcContext, rpcContext.correlationId, "equip")
    local validationResult = EquipService.ValidateOwnedItem(context, itemInstanceId)
    if not validationResult.ok then return validationResult end
    return WeaponRuntime.BeginEquip(source, context.sessionId, validationResult.value.item,
        validationResult.value.definition, context.correlationId)
end

function EquipService.Acknowledge(source, rpcContext, token)
    if type(token) ~= "string" or #token > 256 then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID, "Equip authorization is invalid", nil, rpcContext.correlationId)
    end

    local result = WeaponRuntime.CompleteEquip(source, rpcContext.sessionId, token, rpcContext.correlationId)
    if not result.ok then return result end

    local context = BuildContext(source, rpcContext, rpcContext.correlationId, "equip_commit")
    local persistResult = InventoryAdapter.SetEquippedForCharacter(context, result.value.itemInstanceId)
    if not persistResult.ok then
        WeaponRuntime.Unequip(source, rpcContext.sessionId, rpcContext.correlationId)
        return persistResult
    end
    return result
end

function EquipService.Restore(source, session, itemInstanceId, correlationId)
    local context = BuildContext(source, session, correlationId, "reconcile")
    local validationResult = EquipService.ValidateOwnedItem(context, itemInstanceId)
    if not validationResult.ok then return validationResult end
    return WeaponRuntime.RestoreEquipped(source, session.sessionId, validationResult.value.item,
        validationResult.value.definition, correlationId)
end

function EquipService.Unequip(source, rpcContext)
    local runtime = WeaponRuntime.Get(source)
    if not runtime or runtime.sessionId ~= rpcContext.sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, rpcContext.correlationId)
    end

    local context = BuildContext(source, rpcContext, rpcContext.correlationId, "unequip")
    local persistResult = InventoryAdapter.SetEquippedForCharacter(context, nil)
    if not persistResult.ok then return persistResult end

    local result = WeaponRuntime.Unequip(source, rpcContext.sessionId, rpcContext.correlationId)
    if result.ok then TriggerClientEvent("feather-weapons:client:clearEquipped", source) end
    return result
end

FeatherCore.RPC.Register("feather-weapons:equip:request", function(params, respond, source, context)
    respond(EquipService.Request(source, context, params and params.itemInstanceId))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 4, maxPayloadBytes = 256 })

FeatherCore.RPC.Register("feather-weapons:equip:acknowledge", function(params, respond, source, context)
    respond(EquipService.Acknowledge(source, context, params and params.token))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 6, maxPayloadBytes = 512 })

FeatherCore.RPC.Register("feather-weapons:equip:unequip", function(_, respond, source, context)
    respond(EquipService.Unequip(source, context))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 4, maxPayloadBytes = 64 })
