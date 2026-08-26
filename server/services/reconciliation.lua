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
    local context = ContextForSession(session, ("rehydrate:%s:%s"):format(tostring(session.characterId), tostring(GetGameTimer())))
    local equippedResult = InventoryAdapter.GetEquippedForCharacter(context)
    if not equippedResult.ok or not equippedResult.value then return equippedResult end

    local restoreResult = EquipService.Restore(session.source, session, equippedResult.value, context.correlationId)
    if not restoreResult.ok then
        InventoryAdapter.SetEquippedForCharacter(context, nil)
        print(("[feather-weapons] rejected saved equipped item for character %s: %s")
            :format(tostring(session.characterId), restoreResult.error.code))
    end
    return restoreResult
end

function ReconciliationService.Snapshot(source, sessionId, correlationId)
    local runtime = WeaponRuntime.Get(source)
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, correlationId)
    end

    local equipped = nil
    if runtime.equipped then
        equipped = {
            itemInstanceId = runtime.equipped.itemInstanceId,
            definitionId = runtime.equipped.definitionId,
            nativeWeaponName = runtime.equipped.nativeWeaponName,
            nativeAmmoName = runtime.equipped.nativeAmmoName,
            ammo = runtime.equipped.ammo,
            condition = runtime.equipped.condition,
            attachments = runtime.equipped.attachments or {}
        }
    end
    return WeaponResult.Ok({ state = runtime.state, equipped = equipped }, correlationId)
end

function ReconciliationService.BootstrapActiveSessions()
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local sessionResult = CoreAdapter.ResolveSession(source)
        if sessionResult.ok then
            WeaponRuntime.Begin(sessionResult.value)
            ReconciliationService.RehydrateSession(sessionResult.value)
            TriggerClientEvent("feather-weapons:client:reconcile", source)
        end
    end
end

FeatherCore.RPC.Register("feather-weapons:state:get", function(_, respond, source, context)
    respond(ReconciliationService.Snapshot(source, context.sessionId, context.correlationId))
end, { requireCharacter = true, windowMs = 1000, maxCalls = 4, maxPayloadBytes = 64 })

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent("feather-weapons:client:clearSession", tonumber(playerId))
    end
end)
