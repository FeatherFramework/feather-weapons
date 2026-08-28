CoreAdapter = {}

local function IsUuid(value)
    return type(value) == "string" and value:match(
        "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    ) ~= nil
end

function CoreAdapter.NormalizeCharacterId(value)
    if IsUuid(value) then return value:lower() end
    return nil
end

function CoreAdapter.CheckCapabilities()
    local ready = exports["feather-core"]:AwaitReady(10000)
    if type(ready) ~= "table" or ready.ok ~= true then
        return WeaponResult.Error(WeaponErrors.DEPENDENCY_UNAVAILABLE,
            "feather-core is not ready", ready and ready.error and ready.error.details)
    end

    local reported = exports["feather-core"]:GetCapabilities()
    local capabilities = type(reported) == "table" and reported.ok == true and reported.value or nil
    local contractVersion = capabilities and tonumber(capabilities.contract) or 0
    if contractVersion < Config.RequiredCoreContract then
        return WeaponResult.Error(WeaponErrors.DEPENDENCY_UNAVAILABLE, "feather-core contract is too old", {
            required = Config.RequiredCoreContract,
            actual = capabilities and capabilities.contract or nil
        })
    end
    if not capabilities.features or (tonumber(capabilities.features.sessions) or 0) < 1 then
        return WeaponResult.Error(WeaponErrors.DEPENDENCY_UNAVAILABLE,
            "feather-core session capability is unavailable")
    end
    return WeaponResult.Ok(capabilities)
end

function CoreAdapter.ResolveSession(source)
    local result = exports["feather-core"]:GetSessionContext(tonumber(source))
    if type(result) ~= "table" or result.ok ~= true or type(result.value) ~= "table" then
        return WeaponResult.Error(WeaponErrors.CHARACTER_REQUIRED, "A current character session is required")
    end
    local session = result.value
    local characterId = CoreAdapter.NormalizeCharacterId(session.characterId)
    if not characterId then
        return WeaponResult.Error(WeaponErrors.CHARACTER_REQUIRED,
            "The current character identity is unsupported")
    end
    session.characterId = characterId
    return WeaponResult.Ok(session)
end

function CoreAdapter.IsSessionCurrent(source, sessionId, characterId)
    characterId = CoreAdapter.NormalizeCharacterId(characterId)
    if not characterId then return false end
    return exports["feather-core"]:IsSessionCurrent(tonumber(source), sessionId, characterId) == true
end
