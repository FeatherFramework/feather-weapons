WeaponRuntime = {}
local sessions = {}
local tokenCounter = 0

local function NativeAmmoName(definition)
    local result = DefinitionRegistry.Get("ammunition", definition.ammunitionType)
    return result.ok and result.value.nativeAmmoName or nil
end

local function NextToken(runtime)
    tokenCounter = tokenCounter + 1
    return ("%s:%s:%s:%s"):format(runtime.sessionId, tostring(GetGameTimer()), tostring(tokenCounter), tostring(math.random(100000, 999999)))
end

function WeaponRuntime.Get(source)
    return sessions[source]
end

function WeaponRuntime.Begin(session)
    sessions[session.source] = {
        source = session.source,
        characterId = session.characterId,
        sessionId = session.sessionId,
        equipped = nil,
        pending = nil,
        state = "idle"
    }
    return sessions[session.source]
end

function WeaponRuntime.Clear(source)
    local previous = sessions[source]
    sessions[source] = nil
    return previous
end

function WeaponRuntime.RestoreEquipped(source, sessionId, item, definition, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId or runtime.state == "leaving" then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, correlationId)
    end
    runtime.pending = nil
    runtime.equipped = {
        itemInstanceId = item.id,
        definitionId = definition.id,
        nativeWeaponName = definition.nativeWeaponName,
        nativeAmmoName = NativeAmmoName(definition),
        ammo = item.metadata.ammo and item.metadata.ammo.loaded or 0,
        condition = tonumber(item.metadata.condition) or definition.condition.maximum,
        equippedAt = os.time()
    }
    runtime.state = "equipped"
    return WeaponResult.Ok(runtime.equipped, correlationId)
end

function WeaponRuntime.BeginEquip(source, sessionId, item, definition, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId or runtime.state == "leaving" then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, correlationId)
    end
    if runtime.pending then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Another weapon operation is pending", nil, correlationId)
    end
    if runtime.equipped then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Unequip the current weapon before equipping another", {
            itemInstanceId = runtime.equipped.itemInstanceId
        }, correlationId)
    end

    local token = NextToken(runtime)
    runtime.pending = {
        token = token,
        itemInstanceId = item.id,
        definitionId = definition.id,
        nativeWeaponName = definition.nativeWeaponName,
        nativeAmmoName = NativeAmmoName(definition),
        ammo = item.metadata.ammo and item.metadata.ammo.loaded or 0,
        condition = tonumber(item.metadata.condition) or definition.condition.maximum,
        expiresAt = GetGameTimer() + Config.Runtime.authorizationTtlMs,
        correlationId = correlationId
    }
    runtime.state = "equipping"

    SetTimeout(Config.Runtime.authorizationTtlMs, function()
        local current = sessions[source]
        if not current or not current.pending or current.pending.token ~= token then return end
        current.pending = nil
        current.state = current.equipped and "equipped" or "idle"
        TriggerClientEvent("feather-weapons:client:clearAuthorization", source, token)
    end)

    return WeaponResult.Ok({
        token = token,
        itemInstanceId = item.id,
        definitionId = definition.id,
        nativeWeaponName = definition.nativeWeaponName,
        nativeAmmoName = NativeAmmoName(definition),
        ammo = item.metadata.ammo and item.metadata.ammo.loaded or 0,
        condition = tonumber(item.metadata.condition) or definition.condition.maximum,
        expiresInMs = Config.Runtime.authorizationTtlMs
    }, correlationId)
end

function WeaponRuntime.CompleteEquip(source, sessionId, token, correlationId)
    local runtime = sessions[source]
    local pending = runtime and runtime.pending
    if not runtime or runtime.sessionId ~= sessionId or not pending or pending.token ~= token then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID, "Equip authorization is invalid or expired", nil, correlationId)
    end
    if GetGameTimer() > pending.expiresAt then
        runtime.pending = nil
        runtime.state = runtime.equipped and "equipped" or "idle"
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID, "Equip authorization expired", nil, correlationId)
    end

    runtime.equipped = {
        itemInstanceId = pending.itemInstanceId,
        definitionId = pending.definitionId,
        nativeWeaponName = pending.nativeWeaponName,
        nativeAmmoName = pending.nativeAmmoName,
        ammo = pending.ammo,
        condition = pending.condition,
        equippedAt = os.time()
    }
    runtime.pending = nil
    runtime.state = "equipped"
    return WeaponResult.Ok(runtime.equipped, correlationId)
end

function WeaponRuntime.SetAmmo(source, sessionId, loaded, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, correlationId)
    end
    if not runtime.equipped then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, correlationId)
    end
    local definitionResult = DefinitionRegistry.Get("weapon", runtime.equipped.definitionId)
    if not definitionResult.ok then return definitionResult end
    loaded = math.floor(tonumber(loaded) or -1)
    if loaded < 0 or loaded > definitionResult.value.capacity then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Ammunition is outside weapon capacity", nil, correlationId)
    end
    runtime.equipped.ammo = loaded
    return WeaponResult.Ok({ loaded = loaded }, correlationId)
end

function WeaponRuntime.SetCondition(source, sessionId, condition, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, correlationId)
    end
    if not runtime.equipped then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, correlationId)
    end
    runtime.equipped.condition = tonumber(condition)
    return WeaponResult.Ok({ condition = runtime.equipped.condition }, correlationId)
end

function WeaponRuntime.Unequip(source, sessionId, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil, correlationId)
    end
    if not runtime.equipped and not runtime.pending then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, correlationId)
    end

    local previous = runtime.equipped
    runtime.equipped = nil
    runtime.pending = nil
    runtime.state = "idle"
    return WeaponResult.Ok(previous, correlationId)
end

AddEventHandler("Feather:Server:Character:Ready", function(session)
    WeaponRuntime.Begin(session)
    SetTimeout(0, function()
        if ReconciliationService then ReconciliationService.RehydrateSession(session) end
    end)
end)

AddEventHandler("Feather:Server:Character:Leaving", function(session)
    local runtime = sessions[session.source]
    if runtime and runtime.sessionId == session.sessionId then
        runtime.state = "leaving"
        runtime.pending = nil
        runtime.equipped = nil
        TriggerClientEvent("feather-weapons:client:clearSession", session.source, session.sessionId)
    end
end)

AddEventHandler("Feather:Server:Character:Left", function(session)
    local runtime = sessions[session.source]
    if runtime and runtime.sessionId == session.sessionId then WeaponRuntime.Clear(session.source) end
end)

AddEventHandler("playerDropped", function()
    WeaponRuntime.Clear(source)
end)