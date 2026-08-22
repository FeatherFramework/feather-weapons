RepairService = {}

local function Context(source, rpcContext)
    return {
        actorSource = source,
        actorCharacterId = rpcContext.characterId,
        characterId = rpcContext.characterId,
        sessionId = rpcContext.sessionId,
        correlationId = rpcContext.correlationId,
        reason = "repair",
        resource = "feather-weapons"
    }
end

function RepairService.Repair(source, rpcContext, itemInstanceId)
    if type(itemInstanceId) ~= "string" or itemInstanceId == "" or #itemInstanceId > 128 then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Item instance ID is invalid", nil, rpcContext.correlationId)
    end

    local context = Context(source, rpcContext)
    local transactionResult = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(itemInstanceId)
        if not item then
            return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Weapon item is not owned by this character", nil, context.correlationId)
        end
        local metadata = type(item.metadata) == "table" and item.metadata or nil
        local definitionResult = metadata and DefinitionRegistry.Get("weapon", metadata.weaponDefinitionId) or nil
        if not definitionResult or not definitionResult.ok then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Weapon item metadata is invalid", nil, context.correlationId)
        end
        local definition = definitionResult.value
        if item.itemName ~= definition.itemName then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Item definition does not match weapon metadata", nil, context.correlationId)
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
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Repair material changed during repair", nil, context.correlationId)
        end

        metadata.condition = math.min(definition.condition.maximum, current + repair.restore)
        if not tx:SetMetadata(item.id, metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during repair", nil, context.correlationId)
        end
        return {
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

    local runtime = WeaponRuntime.Get(source)
    if runtime and runtime.sessionId == rpcContext.sessionId and runtime.equipped
        and runtime.equipped.itemInstanceId == itemInstanceId then
        WeaponRuntime.SetCondition(source, rpcContext.sessionId, transactionResult.value.condition, rpcContext.correlationId)
    end
    return WeaponResult.Ok(transactionResult.value, rpcContext.correlationId)
end

FeatherCore.RPC.Register("feather-weapons:repair", function(params, respond, source, context)
    respond(RepairService.Repair(source, context, params and params.itemInstanceId))
end, { requireCharacter = true, windowMs = 2000, maxCalls = 3, maxPayloadBytes = 256 })