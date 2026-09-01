AmmoService = {}

local function Context(source, rpcContext, reason)
    return {
        actorSource = source,
        actorCharacterId = rpcContext.characterId,
        characterId = rpcContext.characterId,
        sessionId = rpcContext.sessionId,
        correlationId = rpcContext.correlationId,
        activeUseToken = rpcContext.activeUseToken,
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

local function ValidateLease(source, equipped, rpcContext, params)
    params = type(params) == "table" and params or {}
    if not WeaponRuntime.MatchesLease(source, rpcContext.sessionId,
        params.itemInstanceId, params.generation) then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID,
            "Weapon runtime lease is stale", {
                expectedGeneration = equipped.generation
            }, rpcContext.correlationId)
    end
    return nil
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

        if tonumber(item.metadata.condition) < definition.condition.equipMinimum then
            return WeaponResult.Error(WeaponErrors.CONDITION_BROKEN, "Weapon condition is too low to reload", {
                condition = item.metadata.condition,
                minimum = definition.condition.equipMinimum
            }, context.correlationId)
        end

        local loaded = tonumber(item.metadata.ammo.loaded) or 0
        local reserve = tonumber(item.metadata.ammo.reserve) or 0
        local total = loaded + reserve
        local maxTotal = math.max(definition.capacity,
            math.floor(tonumber(Config.Escrow and Config.Escrow.maxTotal) or definition.capacity))
        local refillAmount = math.max(1,
            math.floor(tonumber(Config.Escrow and Config.Escrow.refillAmount) or maxTotal))
        local needed = maxTotal - total
        local available = tx:GetQuantity(definition.ammunitionType)
        local moved = math.min(needed, available, requested or refillAmount)
        if moved <= 0 then return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "No compatible ammunition can enter escrow", nil, context.correlationId) end
        if not tx:RemoveQuantity(definition.ammunitionType, moved) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Ammunition changed during reload", nil, context.correlationId)
        end
        local newTotal = total + moved
        local newLoaded = loaded
        if total == 0 and loaded == 0 then
            -- RedM automatically fills an empty cylinder on the next native
            -- update when a positive pool is granted. Persist that native rule
            -- instead of attempting to hold an unstable 0/positive snapshot.
            newLoaded = math.min(definition.capacity, newTotal)
        end
        local newReserve = newTotal - newLoaded
        item.metadata.ammo.loaded = newLoaded
        item.metadata.ammo.reserve = newReserve
        item.metadata.ammo.chambered = newLoaded > 0

        if not tx:SetMetadata(item.id, item.metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during ammunition operation", nil, context.correlationId)
        end
        return {
            total = newTotal,
            loaded = newLoaded,
            reserve = newReserve,
            moved = moved,
            inventoryAmmo = tx:GetQuantity(definition.ammunitionType),
            nativeAmmoName = equipped.nativeAmmoName
        }
    end)
    if not transactionResult.ok then return transactionResult end

    local value = transactionResult.value
    WeaponRuntime.SetAmmo(source, rpcContext.sessionId, value.total, value.loaded, rpcContext.correlationId)
    return WeaponResult.Ok(value, rpcContext.correlationId)
end

function AmmoService.Escrow(source, rpcContext, amount)
    return Reload(source, rpcContext, amount)
end

function AmmoService.Unload(source, rpcContext, requested)
    local equipped, failure = GetEquipped(source, rpcContext)
    if not equipped then return failure end
    if requested ~= nil then requested = math.floor(tonumber(requested) or -1) end
    if requested ~= nil and requested < 1 then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Ammunition amount must be a positive integer", nil,
            rpcContext.correlationId)
    end

    local definitionResult = DefinitionRegistry.Get("weapon", equipped.definitionId)
    if not definitionResult.ok then return definitionResult end
    local definition = definitionResult.value
    local context = Context(source, rpcContext, "unload")
    local transactionResult = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(equipped.itemInstanceId)
        if not item then
            return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Equipped weapon is no longer owned", nil,
                context.correlationId)
        end
        local metadataResult = WeaponMetadata.Validate(item.metadata, definition, context.correlationId)
        if not metadataResult.ok then return metadataResult end

        local loaded = tonumber(item.metadata.ammo.loaded) or 0
        local reserve = tonumber(item.metadata.ammo.reserve) or 0
        local total = loaded + reserve
        local moved = math.min(total, requested or total)
        if moved <= 0 then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "The equipped weapon is already empty", nil,
                context.correlationId)
        end
        if not tx:AddQuantity(definition.ammunitionType, moved) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
                "Inventory cannot accept the unloaded ammunition", nil, context.correlationId)
        end

        local remaining = total - moved
        item.metadata.ammo.loaded = math.min(loaded, remaining)
        item.metadata.ammo.reserve = remaining - item.metadata.ammo.loaded
        item.metadata.ammo.chambered = item.metadata.ammo.loaded > 0
        if not tx:SetMetadata(item.id, item.metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
                "Weapon metadata changed during ammunition operation", nil, context.correlationId)
        end
        return {
            total = remaining,
            loaded = item.metadata.ammo.loaded,
            reserve = item.metadata.ammo.reserve,
            moved = moved,
            inventoryAmmo = tx:GetQuantity(definition.ammunitionType),
            nativeAmmoName = equipped.nativeAmmoName
        }
    end)
    if not transactionResult.ok then return transactionResult end

    WeaponRuntime.SetAmmo(source, rpcContext.sessionId, transactionResult.value.total,
        transactionResult.value.loaded, rpcContext.correlationId)
    return WeaponResult.Ok(transactionResult.value, rpcContext.correlationId)
end

function AmmoService.SyncConsumption(source, rpcContext, params)
    local equipped, failure = GetEquipped(source, rpcContext)
    if not equipped then return failure end
    local leaseFailure = ValidateLease(source, equipped, rpcContext, params)
    if leaseFailure then return leaseFailure end
    local reportedTotal = math.floor(tonumber(params and params.total) or -1)
    local reportedLoaded = math.floor(tonumber(params and params.loaded) or -1)
    local definitionResult = DefinitionRegistry.Get("weapon", equipped.definitionId)
    if not definitionResult.ok then return definitionResult end
    if reportedTotal < 0 or reportedTotal > equipped.ammo or reportedLoaded < 0
        or reportedLoaded > definitionResult.value.capacity or reportedLoaded > reportedTotal then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Reported ammunition is outside the approved range", nil, rpcContext.correlationId)
    end
    local context = Context(source, rpcContext, "fire_checkpoint")
    local transactionResult = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(equipped.itemInstanceId)
        if not item then return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Equipped weapon is no longer owned", nil, context.correlationId) end
        local current = tonumber(item.metadata.ammo.loaded) or 0
        local currentReserve = tonumber(item.metadata.ammo.reserve) or 0
        local currentTotal = current + currentReserve
        if reportedTotal > currentTotal then
            return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Ammunition increases are not accepted from the client", nil, context.correlationId)
        end
        local consumed = currentTotal - reportedTotal
        local condition = tonumber(item.metadata.condition) or definitionResult.value.condition.maximum
        local wear = consumed * definitionResult.value.condition.wearPerShot
        item.metadata.ammo.loaded = reportedLoaded
        item.metadata.ammo.reserve = reportedTotal - reportedLoaded
        item.metadata.ammo.chambered = reportedLoaded > 0
        item.metadata.condition = math.max(definitionResult.value.condition.minimum, condition - wear)
        if not tx:SetMetadata(item.id, item.metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during ammunition checkpoint", nil, context.correlationId)
        end
        return {
            total = reportedTotal,
            loaded = reportedLoaded,
            reserve = reportedTotal - reportedLoaded,
            consumed = consumed,
            condition = item.metadata.condition,
            broken = item.metadata.condition < definitionResult.value.condition.equipMinimum
        }
    end)
    if not transactionResult.ok then return transactionResult end
    WeaponRuntime.SetAmmo(source, rpcContext.sessionId, reportedTotal, reportedLoaded, rpcContext.correlationId)
    WeaponRuntime.SetCondition(source, rpcContext.sessionId, transactionResult.value.condition, rpcContext.correlationId)
    if transactionResult.value.broken then
        local persistResult = InventoryAdapter.SetEquippedForCharacter(context, nil)
        if not persistResult.ok then return persistResult end
        WeaponRuntime.Unequip(source, rpcContext.sessionId, rpcContext.correlationId)
    end
    return WeaponResult.Ok(transactionResult.value, rpcContext.correlationId)
end

FeatherCore.RPC.Register("feather-weapons:ammo:unload", function(params, respond, source, context)
    respond(AmmoService.Unload(source, context, params and params.amount))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 4, maxPayloadBytes = 128 })

FeatherCore.RPC.Register("feather-weapons:ammo:sync", function(params, respond, source, context)
    respond(AmmoService.SyncConsumption(source, context, params))
end, { requireCharacter = true, windowMs = 5000, maxCalls = 12, maxPayloadBytes = 256 })
