RepairService = {}
local pendingSelections = {}

local function Context(source, rpcContext)
    return {
        actorSource = source,
        actorCharacterId = rpcContext.characterId,
        characterId = rpcContext.characterId,
        sessionId = rpcContext.sessionId,
        correlationId = rpcContext.correlationId,
        activeUseToken = rpcContext.activeUseToken,
        reason = "repair",
        resource = "feather-weapons"
    }
end

function RepairService.Repair(source, rpcContext, request)
    request = type(request) == "table" and request or {}
    local slot = WeaponRuntime.NormalizeSlot(request.slot)
    local itemInstanceId = request.itemInstanceId
    local generation = tonumber(request.generation)
    if not slot then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Weapon equipment slot is invalid", nil,
            rpcContext.correlationId)
    end
    local idType = type(itemInstanceId)
    if (idType ~= "string" and idType ~= "number")
        or (idType == "string" and (itemInstanceId == "" or #itemInstanceId > 128))
        or (idType == "number" and (itemInstanceId < 1 or itemInstanceId % 1 ~= 0)) then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Item instance ID is invalid", nil,
            rpcContext.correlationId)
    end
    if not generation or not WeaponRuntime.MatchesLease(
        source, rpcContext.sessionId, itemInstanceId, generation, slot) then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED,
            "The equipped weapon lease is no longer current", { slot = slot }, rpcContext.correlationId)
    end

    local context = Context(source, rpcContext)
    local transactionResult = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(itemInstanceId)
        if not item then
            return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Weapon item is not owned by this character", nil,
                context.correlationId)
        end
        if type(item.metadata) ~= "table" then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Weapon item metadata is invalid", nil,
                context.correlationId)
        end

        local metadata = item.metadata
        local definitionResult = DefinitionRegistry.Get("weapon", metadata.weaponDefinitionId)
        if not definitionResult or not definitionResult.ok then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Weapon item metadata is invalid", nil,
                context.correlationId)
        end
        local definition = definitionResult.value
        if item.itemName ~= definition.itemName then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Item definition does not match weapon metadata", nil,
                context.correlationId)
        end
        local metadataResult = WeaponMetadata.Validate(metadata, definition, context.correlationId)
        if not metadataResult.ok then return metadataResult end

        local current = tonumber(metadata.condition) or definition.condition.minimum
        if current >= definition.condition.maximum then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon condition is already full", {
                condition = current
            }, context.correlationId)
        end

        local repair = definition.condition.repair
        if tx:GetQuantity(repair.itemDefinitionId) < repair.quantity then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Required repair material is unavailable", {
                itemDefinitionId = repair.itemDefinitionId,
                required = repair.quantity
            }, context.correlationId)
        end
        if not tx:RemoveQuantity(repair.itemDefinitionId, repair.quantity) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Repair material changed during repair", nil,
                context.correlationId)
        end

        metadata.condition = math.min(definition.condition.maximum, current + repair.restore)
        if not tx:SetMetadata(item.id, metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during repair", nil,
                context.correlationId)
        end
        return {
            slot = slot,
            generation = generation,
            itemInstanceId = item.id,
            previousCondition = current,
            condition = metadata.condition,
            restored = metadata.condition - current,
            material = repair.itemDefinitionId,
            materialConsumed = repair.quantity,
            materialRemaining = tx:GetQuantity(repair.itemDefinitionId),
            broken = metadata.condition < definition.condition.equipMinimum
        }
    end)
    if not transactionResult.ok then return transactionResult end

    if WeaponRuntime.MatchesLease(source, rpcContext.sessionId, itemInstanceId, generation, slot) then
        WeaponRuntime.SetSlotCondition(source, rpcContext.sessionId, slot,
            transactionResult.value.condition, rpcContext.correlationId)
    end
    return WeaponResult.Ok(transactionResult.value, rpcContext.correlationId)
end

function RepairService.BeginSelection(source, rpcContext, done)
    if pendingSelections[source] then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            "A repair selection is already pending", nil, rpcContext.correlationId)
    end
    local runtime = WeaponRuntime.Get(source)
    if not runtime or runtime.sessionId ~= rpcContext.sessionId
        or not runtime.slots or not runtime.slots.primary or not runtime.slots.offhand then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED,
            "Two equipped weapons are required for repair selection", nil,
            rpcContext.correlationId)
    end
    local pending = {
        context = rpcContext,
        done = done,
        slots = {
            primary = {
                itemInstanceId = runtime.slots.primary.itemInstanceId,
                generation = runtime.slots.primary.generation
            },
            offhand = {
                itemInstanceId = runtime.slots.offhand.itemInstanceId,
                generation = runtime.slots.offhand.generation
            }
        }
    }
    pendingSelections[source] = pending
    TriggerClientEvent("feather-weapons:client:repairSlotRequested", source)
    SetTimeout(15000, function()
        if pendingSelections[source] ~= pending then return end
        pendingSelections[source] = nil
        TriggerClientEvent("feather-weapons:client:inventoryRepairResult", source,
            WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
                "Repair selection timed out", nil, rpcContext.correlationId))
        if pending.done then pending.done() end
    end)
    return WeaponResult.Ok({ pending = true }, rpcContext.correlationId)
end

function RepairService.Select(source, rpcContext, request)
    local pending = pendingSelections[source]
    if not pending or pending.context.sessionId ~= rpcContext.sessionId then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            "No repair selection is pending", nil, rpcContext.correlationId)
    end
    local slot = WeaponRuntime.NormalizeSlot(type(request) == "table" and request.slot or nil)
    local selected = slot and pending.slots[slot] or nil
    if not selected then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID,
            "Weapon equipment slot is invalid", nil, rpcContext.correlationId)
    end
    pendingSelections[source] = nil
    local result = RepairService.Repair(source, pending.context, {
        slot = slot,
        itemInstanceId = selected.itemInstanceId,
        generation = selected.generation
    })
    if pending.done then pending.done() end
    return result
end

FeatherCore.RPC.Register("feather-weapons:repair", function(params, respond, source, context)
    respond(RepairService.Repair(source, context, params))
end, { requireCharacter = true, windowMs = 2000, maxCalls = 3, maxPayloadBytes = 256 })

FeatherCore.RPC.Register("feather-weapons:repair:select", function(params, respond, source, context)
    respond(RepairService.Select(source, context, params))
end, { requireCharacter = true, windowMs = 2000, maxCalls = 3, maxPayloadBytes = 128 })
