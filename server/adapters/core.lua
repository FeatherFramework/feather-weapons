CoreAdapter = {}

function CoreAdapter.CheckCapabilities()
    if not FeatherCore or not FeatherCore.Character or not FeatherCore.Character.GetCapabilities then
        return WeaponResult.Error(WeaponErrors.DEPENDENCY_UNAVAILABLE, "feather-core does not expose character capabilities")
    end

    local capabilities = FeatherCore.Character.GetCapabilities()
    local contractVersion = capabilities and tonumber(capabilities.contractVersion) or 0
    if contractVersion < Config.RequiredCoreContract then
        return WeaponResult.Error(WeaponErrors.DEPENDENCY_UNAVAILABLE, "feather-core character contract is too old", {
            required = Config.RequiredCoreContract,
            actual = capabilities and capabilities.contractVersion or nil
        })
    end
    return WeaponResult.Ok(capabilities)
end

function CoreAdapter.ResolveSession(source)
    local session = FeatherCore.Character.ResolveSession(source)
    if not session then
        return WeaponResult.Error(WeaponErrors.CHARACTER_REQUIRED, "A current character session is required")
    end
    return WeaponResult.Ok(session)
end

function CoreAdapter.IsSessionCurrent(source, sessionId, characterId)
    return FeatherCore.Character.IsSessionCurrent(source, sessionId, characterId)
end
