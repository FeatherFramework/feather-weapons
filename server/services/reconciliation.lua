ReconciliationService = {}

local function ContextForSession(session, correlationId)
    return {
        actorSource = session.source,
        actorCharacterId = session.characterId,
        characterId = session.characterId,
        sessionId = session.sessionId,
        correlationId = correlationId,
        reason = "reconcile",
        resource = "feather-weapons"
    }
end

function ReconciliationService.RehydrateSession(session)
    local context = ContextForSession(session,
        ("rehydrate:%s:%s"):format(tostring(session.characterId), tostring(GetGameTimer())))
    local equippedResult = InventoryAdapter.GetEquippedSlotsForCharacter(context)
    if not equippedResult.ok then return equippedResult end

    local restored = {}
    for _, slot in ipairs({ "primary", "offhand" }) do
        local itemInstanceId = equippedResult.value and equippedResult.value[slot] or nil
        if itemInstanceId then
            local restoreResult = EquipService.Restore(
                session.source, session, itemInstanceId, context.correlationId, slot)
            if not restoreResult.ok then
                InventoryAdapter.SetEquippedSlotForCharacter(context, slot, nil)
                print(("[feather-weapons] rejected saved equipped item character=%s slot=%s code=%s")
                    :format(tostring(session.characterId), slot, restoreResult.error.code))
            else
                restored[slot] = restoreResult.value
            end
        end
    end
    return WeaponResult.Ok({ slots = restored, equipped = restored.primary }, context.correlationId)
end

function ReconciliationService.Snapshot(source, sessionId, correlationId)
    local runtime = WeaponRuntime.Get(source)
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
    end

    local equipped = nil
    if runtime.equipped then
        equipped = {
            itemInstanceId = runtime.equipped.itemInstanceId,
            definitionId = runtime.equipped.definitionId,
            nativeWeaponName = runtime.equipped.nativeWeaponName,
            nativeAmmoName = runtime.equipped.nativeAmmoName,
            ammo = runtime.equipped.ammo,
            loaded = runtime.equipped.loaded,
            reserve = runtime.equipped.reserve,
            condition = runtime.equipped.condition,
            generation = runtime.equipped.generation,
            sessionId = runtime.equipped.sessionId,
            attachments = runtime.equipped.attachments or {}
        }
    end
    local slots = {}
    for _, slot in ipairs({ "primary", "offhand" }) do
        local value = runtime.slots and runtime.slots[slot] or nil
        if value then
            slots[slot] = {
                slot = slot,
                itemInstanceId = value.itemInstanceId,
                definitionId = value.definitionId,
                nativeWeaponName = value.nativeWeaponName,
                nativeAmmoName = value.nativeAmmoName,
                ammo = value.ammo,
                loaded = value.loaded,
                reserve = value.reserve,
                condition = value.condition,
                generation = value.generation,
                sessionId = value.sessionId,
                attachments = value.attachments or {}
            }
        end
    end
    return WeaponResult.Ok({ state = runtime.state, equipped = equipped, slots = slots }, correlationId)
end

function ReconciliationService.InspectMetadata(source)
    local sessionResult = CoreAdapter.ResolveSession(source)
    if not sessionResult.ok then return sessionResult end
    local session = sessionResult.value
    local context = ContextForSession(session,
        ("metadata-inspect:%s:%s"):format(tostring(source), tostring(GetGameTimer())))
    local equippedResult = InventoryAdapter.GetEquippedSlotsForCharacter(context)
    if not equippedResult.ok then return equippedResult end
    local runtime = WeaponRuntime.Get(source)
    local slots = {}
    for _, slot in ipairs({ "primary", "offhand" }) do
        local itemInstanceId = equippedResult.value and equippedResult.value[slot] or nil
        if itemInstanceId then
            local itemResult = InventoryAdapter.GetItemForCharacter(context, itemInstanceId)
            if not itemResult.ok then return itemResult end
            local item = itemResult.value
            local definitionId = item.metadata and item.metadata.weaponDefinitionId
            local definitionResult = DefinitionRegistry.Get("weapon", definitionId)
            if not definitionResult.ok then return definitionResult end
            local validation = WeaponMetadata.Validate(
                item.metadata, definitionResult.value, context.correlationId)
            if not validation.ok then return validation end
            local runtimeItem = runtime and runtime.slots and runtime.slots[slot]
            slots[slot] = {
                slot = slot,
                itemInstanceId = item.id,
                definitionId = definitionId,
                serialNumber = item.metadata.serialNumber,
                condition = item.metadata.condition,
                loaded = item.metadata.ammo.loaded,
                reserve = item.metadata.ammo.reserve,
                attachments = item.metadata.attachments or {},
                runtimeMatches = runtimeItem ~= nil
                    and tostring(runtimeItem.itemInstanceId) == tostring(item.id),
                generation = runtimeItem and runtimeItem.generation or nil
            }
        end
    end
    return WeaponResult.Ok({
        equipped = slots.primary ~= nil or slots.offhand ~= nil,
        characterId = session.characterId,
        slots = slots
    }, context.correlationId)
end

function ReconciliationService.Force(source)
    local sessionResult = CoreAdapter.ResolveSession(source)
    if not sessionResult.ok then return sessionResult end
    local session = sessionResult.value
    local reset = WeaponRuntime.ResetForReconcile(source, session.sessionId,
        ("forced-reconcile-reset:%s:%s"):format(tostring(source), tostring(GetGameTimer())))
    if not reset.ok then return reset end
    local restored = ReconciliationService.RehydrateSession(session)
    if not restored.ok then
        TriggerClientEvent("feather-weapons:client:clear", source)
        return restored
    end
    TriggerClientEvent("feather-weapons:client:forceReconcile", source)
    return ReconciliationService.Snapshot(source, session.sessionId,
        ("forced-reconcile:%s:%s"):format(tostring(source), tostring(GetGameTimer())))
end

function ReconciliationService.BootstrapActiveSessions()
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local sessionResult = CoreAdapter.ResolveSession(source)
            if sessionResult.ok then
                WeaponRuntime.Begin(sessionResult.value)
                ReconciliationService.RehydrateSession(sessionResult.value)
                TriggerClientEvent("feather-weapons:client:reconcile", source)
            end
        end
    end
end

FeatherCore.RPC.Register("feather-weapons:state:get", function(_, respond, source, context)
    respond(ReconciliationService.Snapshot(source, context.sessionId, context.correlationId))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 4, maxPayloadBytes = 64 })

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            TriggerClientEvent("feather-weapons:client:clear", source)
        end
    end
end)
