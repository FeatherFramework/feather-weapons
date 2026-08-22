AmmoService = {}

local function Context(source, rpcContext, reason)
    return {
        actorSource = source,
        actorCharacterId = rpcContext.characterId,
        characterId = rpcContext.characterId,
        sessionId = rpcContext.sessionId,
        correlationId = rpcContext.correlationId,
        reason = reason,
        resource = "feather-weapons"
    }
end

local function GetEquipped(source, rpcContext)
    local runtime = WeaponRuntime.Get(source)
    if not runtime or runtime.sessionId ~= rpcContext.sessionId or not runtime.equipped then
        return nil, WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, rpcContext.correlationId)
    end
    return runtime.equipped
end

local function Reload(source, rpcContext, requested)
    local equipped, failure = GetEquipped(source, rpcContext)
    if not equipped then return failure end
    if requested ~= nil then
        requested = math.floor(tonumber(requested) or -1)
    end
    if requested ~= nil and requested < 1 then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Ammunition amount must be a positive integer", nil, rpcContext.correlationId)
    end

    local definitionResult = DefinitionRegistry.Get("weapon", equipped.definitionId)
    if not definitionResult.ok then return definitionResult end
    local definition = definitionResult.value
    local context = Context(source, rpcContext, "reload")

    local transactionResult = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(equipped.itemInstanceId)
        if not item then return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Equipped weapon is no longer owned", nil, context.correlationId) end
        local metadataResult = WeaponMetadata.Validate(item.metadata, definition, context.correlationId)
        if not metadataResult.ok then return metadataResult end

        local loaded = tonumber(item.metadata.ammo.loaded) or 0
        local needed = definition.capacity - loaded
        local available = tx:GetQuantity(definition.ammunitionType)
        local moved = math.min(needed, available, requested or needed)
        if moved <= 0 then return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "No compatible ammunition can be loaded", nil, context.correlationId) end
        if not tx:RemoveQuantity(definition.ammunitionType, moved) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Ammunition changed during reload", nil, context.correlationId)
        end
        item.metadata.ammo.loaded = loaded + moved
        item.metadata.ammo.chambered = item.metadata.ammo.loaded > 0

        if not tx:SetMetadata(item.id, item.metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during ammunition operation", nil, context.correlationId)
        end
        return {
            loaded = item.metadata.ammo.loaded,
            moved = moved,
            inventoryAmmo = tx:GetQuantity(definition.ammunitionType),
            nativeAmmoName = equipped.nativeAmmoName
        }
    end)
    if not transactionResult.ok then return transactionResult end

    local value = transactionResult.value
    WeaponRuntime.SetAmmo(source, rpcContext.sessionId, value.loaded, rpcContext.correlationId)
    return WeaponResult.Ok(value, rpcContext.correlationId)
end

function AmmoService.Reload(source, rpcContext, amount)
    return Reload(source, rpcContext, amount)
end

function AmmoService.SyncConsumption(source, rpcContext, reportedLoaded)
    local equipped, failure = GetEquipped(source, rpcContext)
    if not equipped then return failure end
    reportedLoaded = math.floor(tonumber(reportedLoaded) or -1)
    if reportedLoaded < 0 or reportedLoaded > equipped.ammo then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Reported ammunition is outside the approved range", nil, rpcContext.correlationId)
    end
    if reportedLoaded == equipped.ammo then return WeaponResult.Ok({ loaded = equipped.ammo, consumed = 0 }, rpcContext.correlationId) end

    local definitionResult = DefinitionRegistry.Get("weapon", equipped.definitionId)
    if not definitionResult.ok then return definitionResult end
    local context = Context(source, rpcContext, "fire_checkpoint")
    local transactionResult = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(equipped.itemInstanceId)
        if not item then return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Equipped weapon is no longer owned", nil, context.correlationId) end
        local current = tonumber(item.metadata.ammo.loaded) or 0
        if reportedLoaded > current then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Ammunition increases are not accepted from the client", nil, context.correlationId)
        end
        item.metadata.ammo.loaded = reportedLoaded
        item.metadata.ammo.chambered = reportedLoaded > 0
        if not tx:SetMetadata(item.id, item.metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during ammunition checkpoint", nil, context.correlationId)
        end
        return { loaded = reportedLoaded, consumed = current - reportedLoaded }
    end)
    if not transactionResult.ok then return transactionResult end
    WeaponRuntime.SetAmmo(source, rpcContext.sessionId, reportedLoaded, rpcContext.correlationId)
    return WeaponResult.Ok(transactionResult.value, rpcContext.correlationId)
end

FeatherCore.RPC.Register("feather-weapons:ammo:reload", function(params, respond, source, context)
    respond(AmmoService.Reload(source, context, params and params.amount))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 4, maxPayloadBytes = 128 })

FeatherCore.RPC.Register("feather-weapons:ammo:sync", function(params, respond, source, context)
    respond(AmmoService.SyncConsumption(source, context, params and params.loaded))
end, { requireCharacter = true, windowMs = 5000, maxCalls = 12, maxPayloadBytes = 128 })
