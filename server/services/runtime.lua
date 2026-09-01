WeaponRuntime = {}
local sessions = {}
local tokenCounter = 0

local function NextGeneration(runtime)
    runtime.generation = (tonumber(runtime.generation) or 0) + 1
    return runtime.generation
end

local function NativeAmmoName(definition)
    local result = DefinitionRegistry.Get("ammunition", definition.ammunitionType)
    return result.ok and result.value.nativeAmmoName or nil
end

local function InstalledAttachments(metadata)
    local result = {}
    for _, installed in ipairs(metadata.attachments or {}) do
        local definition = DefinitionRegistry.Get("attachment", installed.definitionId)
        if definition.ok then
            result[#result + 1] = {
                definitionId = definition.value.id,
                slot = definition.value.slot,
                nativeComponentName = definition.value.nativeComponentName
            }
        end
    end
    return result
end

local function NextToken(runtime)
    tokenCounter = tokenCounter + 1
    return ("%s:%s:%s:%s"):format(runtime.sessionId, tostring(GetGameTimer()), tostring(tokenCounter),
        tostring(math.random(100000, 999999)))
end

function WeaponRuntime.Get(source)
    return sessions[source]
end

local function AmmoSnapshot(metadata, definition)
    local loaded = math.max(0, math.min(definition.capacity,
        math.floor(tonumber(metadata.ammo and metadata.ammo.loaded) or 0)))
    local reserve = math.max(0, math.floor(tonumber(metadata.ammo and metadata.ammo.reserve) or 0))
    return loaded, reserve, loaded + reserve
end

function WeaponRuntime.MatchesLease(source, sessionId, itemInstanceId, generation)
    local runtime = sessions[tonumber(source) or source]
    local equipped = runtime and runtime.equipped
    return runtime ~= nil and equipped ~= nil
        and tostring(runtime.sessionId or "") == tostring(sessionId or "")
        and tostring(equipped.sessionId or "") == tostring(sessionId or "")
        and tostring(equipped.itemInstanceId or "") == tostring(itemInstanceId or "")
        and tonumber(equipped.generation) == tonumber(generation)
end

function WeaponRuntime.Begin(session)
    sessions[session.source] = {
        source = session.source,
        characterId = session.characterId,
        sessionId = session.sessionId,
        equipped = nil,
        pending = nil,
        generation = 0,
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
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
    end
    runtime.pending = nil
    local generation = NextGeneration(runtime)
    local loaded, reserve, total = AmmoSnapshot(item.metadata, definition)
    runtime.equipped = {
        itemInstanceId = item.id,
        definitionId = definition.id,
        nativeWeaponName = definition.nativeWeaponName,
        nativeAmmoName = NativeAmmoName(definition),
        ammo = total,
        loaded = loaded,
        reserve = reserve,
        condition = tonumber(item.metadata.condition) or definition.condition.maximum,
        attachments = InstalledAttachments(item.metadata),
        generation = generation,
        sessionId = runtime.sessionId,
        equippedAt = os.time()
    }
    runtime.state = "equipped"
    return WeaponResult.Ok(runtime.equipped, correlationId)
end

function WeaponRuntime.BeginEquip(source, sessionId, item, definition, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId or runtime.state == "leaving" then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
    end
    if runtime.pending then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Another weapon operation is pending", nil,
            correlationId)
    end
    if runtime.equipped then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Unequip the current weapon before equipping another",
            {
                itemInstanceId = runtime.equipped.itemInstanceId
            }, correlationId)
    end

    local token = NextToken(runtime)
    local loaded, reserve, total = AmmoSnapshot(item.metadata, definition)
    runtime.pending = {
        token = token,
        itemInstanceId = item.id,
        definitionId = definition.id,
        nativeWeaponName = definition.nativeWeaponName,
        nativeAmmoName = NativeAmmoName(definition),
        ammo = total,
        loaded = loaded,
        reserve = reserve,
        condition = tonumber(item.metadata.condition) or definition.condition.maximum,
        attachments = InstalledAttachments(item.metadata),
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
        ammo = total,
        loaded = loaded,
        reserve = reserve,
        condition = tonumber(item.metadata.condition) or definition.condition.maximum,
        attachments = InstalledAttachments(item.metadata),
        expiresInMs = Config.Runtime.authorizationTtlMs
    }, correlationId)
end

function WeaponRuntime.CompleteEquip(source, sessionId, token, correlationId)
    local runtime = sessions[source]
    local pending = runtime and runtime.pending
    if not runtime or runtime.sessionId ~= sessionId or not pending or pending.token ~= token then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID, "Equip authorization is invalid or expired", nil,
            correlationId)
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
        loaded = pending.loaded,
        reserve = pending.reserve,
        condition = pending.condition,
        attachments = pending.attachments,
        generation = NextGeneration(runtime),
        sessionId = runtime.sessionId,
        equippedAt = os.time()
    }
    runtime.pending = nil
    runtime.state = "equipped"
    return WeaponResult.Ok(runtime.equipped, correlationId)
end

function WeaponRuntime.SetAmmo(source, sessionId, total, loaded, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
    end
    if not runtime.equipped then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, correlationId)
    end
    local definitionResult = DefinitionRegistry.Get("weapon", runtime.equipped.definitionId)
    if not definitionResult.ok then return definitionResult end
    total = math.floor(tonumber(total) or -1)
    loaded = math.floor(tonumber(loaded) or -1)
    local maxTotal = math.max(definitionResult.value.capacity,
        math.floor(tonumber(Config.Escrow and Config.Escrow.maxTotal) or definitionResult.value.capacity))
    if total < 0 or total > maxTotal or loaded < 0
        or loaded > definitionResult.value.capacity or loaded > total then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Ammunition is outside weapon capacity", nil, correlationId)
    end
    runtime.equipped.ammo = total
    runtime.equipped.loaded = loaded
    runtime.equipped.reserve = total - loaded
    return WeaponResult.Ok({ total = total, loaded = loaded, reserve = total - loaded }, correlationId)
end

function WeaponRuntime.ResetForReconcile(source, sessionId, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId or runtime.state == "leaving" then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED,
            "Character session is no longer active", nil, correlationId)
    end
    runtime.pending = nil
    runtime.equipped = nil
    runtime.state = "idle"
    return WeaponResult.Ok({ generation = runtime.generation }, correlationId)
end

function WeaponRuntime.SetCondition(source, sessionId, condition, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
    end
    if not runtime.equipped then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, correlationId)
    end
    runtime.equipped.condition = tonumber(condition)
    return WeaponResult.Ok({ condition = runtime.equipped.condition }, correlationId)
end

function WeaponRuntime.SetAttachments(source, sessionId, attachments, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
    end
    if not runtime.equipped then
        return WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "No weapon is equipped", nil, correlationId)
    end
    runtime.equipped.attachments = attachments or {}
    return WeaponResult.Ok({ attachments = runtime.equipped.attachments }, correlationId)
end

function WeaponRuntime.Unequip(source, sessionId, correlationId)
    local runtime = sessions[source]
    if not runtime or runtime.sessionId ~= sessionId then
        return WeaponResult.Error(WeaponErrors.SESSION_EXPIRED, "Character session is no longer active", nil,
            correlationId)
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

AddEventHandler("core.session.ready.v1", function(session)
    local characterId = session and CoreAdapter.NormalizeCharacterId(session.characterId)
    if not characterId then return end
    session.characterId = characterId
    WeaponRuntime.Begin(session)
    if ReconciliationService then ReconciliationService.RehydrateSession(session) end
end)

AddEventHandler("core.session.leaving.v1", function(session)
    local runtime = sessions[session.source]
    if runtime and runtime.sessionId == session.sessionId then
        runtime.state = "leaving"
        runtime.pending = nil
        runtime.equipped = nil
        TriggerClientEvent("feather-weapons:client:clearSession", session.source, session.sessionId)
    end
end)

AddEventHandler("core.session.left.v1", function(session)
    local runtime = sessions[session.source]
    if runtime and runtime.sessionId == session.sessionId then WeaponRuntime.Clear(session.source) end
end)

AddEventHandler("playerDropped", function()
    WeaponRuntime.Clear(source)
end)
