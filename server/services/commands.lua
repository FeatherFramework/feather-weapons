local function Notify(source, message, duration)
    local result = exports["feather-core"]:SendNotification({
        source = source,
        style = "right",
        message = message,
        duration = duration
    })
    if not result or result.ok ~= true then
        print(("[feather-weapons] notification failed source=%s code=%s")
            :format(tostring(source), tostring(result and result.code or "invalid_result")))
    end
end

if Config.DevMode then
    RegisterCommand("WeaponCharacterIdentitySmokeTest", function(source, args)
        if source ~= 0 then return end
        local targetSource = tonumber(args and args[1])
        if not targetSource then
            local players = GetPlayers()
            targetSource = players[1] and tonumber(players[1]) or nil
        end

        local coreCapabilities = CoreAdapter.CheckCapabilities()
        local session = targetSource and CoreAdapter.ResolveSession(targetSource)
            or WeaponResult.Error(WeaponErrors.CHARACTER_REQUIRED, "No connected player is available")
        local inventoryCapabilities = InventoryAdapter.GetCapabilities()
        local expectedMode = "uuid"
        local tests = {
            { name = "core session capability", passed = coreCapabilities.ok == true },
            { name = "current session resolved", passed = session.ok == true,
                detail = targetSource and ("source=" .. tostring(targetSource)) or "no player" },
            { name = "character id accepted", passed = session.ok == true
                and CoreAdapter.NormalizeCharacterId(session.value.characterId) == session.value.characterId },
            { name = "session is current", passed = session.ok == true
                and CoreAdapter.IsSessionCurrent(targetSource, session.value.sessionId, session.value.characterId) },
            { name = "inventory identity mode", passed = type(inventoryCapabilities) == "table"
                and type(inventoryCapabilities.characterIdentity) == "table"
                and inventoryCapabilities.characterIdentity.uuid == true
                and inventoryCapabilities.characterIdentity.mode == expectedMode,
                detail = "mode=" .. tostring(expectedMode) }
        }

        local passed = 0
        for _, test in ipairs(tests) do
            if test.passed then passed = passed + 1 end
            print(("[WeaponCharacterIdentitySmokeTest] %-27s %s%s"):format(
                test.name, test.passed and "PASS" or "FAIL",
                test.detail and ("  -- " .. test.detail) or ""))
        end
        print(("[WeaponCharacterIdentitySmokeTest] done %d/%d passed"):format(passed, #tests))
    end, true)

    RegisterCommand("grantweapon", function(source, args)
        local definitionId = args[1] or "cattleman_revolver"
        local targetSource = tonumber(args[2]) or (source > 0 and source or nil)
        if not targetSource then
            print("[feather-weapons] usage: grantweapon [definitionId] [targetServerId]")
            return
        end

        local targetSession = CoreAdapter.ResolveSession(targetSource)
        if not targetSession.ok then
            print(("[feather-weapons] grant failed: %s"):format(targetSession.error.message))
            return
        end

        local actorCharacterId = nil
        if source > 0 then
            local actorSession = CoreAdapter.ResolveSession(source)
            actorCharacterId = actorSession.ok and actorSession.value.characterId or nil
        end

        local result = IssuanceService.Issue({
            actorSource = source == targetSource and source or nil,
            actorCharacterId = actorCharacterId,
            characterId = targetSession.value.characterId,
            sessionId = targetSession.value.sessionId,
            correlationId = ("dev-grant:%s:%s"):format(tostring(targetSource), tostring(GetGameTimer())),
            reason = "development_grant",
            resource = "feather-weapons"
        }, {
            characterId = targetSession.value.characterId,
            definitionId = definitionId,
            provenance = { type = "development_grant" }
        })

        if not result.ok then
            local message = ("Weapon grant failed: %s"):format(result.error.message)
            print(("[feather-weapons] %s"):format(message))
            if source > 0 then Notify(source, message, 4000) end
            return
        end

        print(("[feather-weapons] granted definition=%s item=%s serial=%s character=%s")
            :format(result.value.definitionId, tostring(result.value.itemInstanceId),
                result.value.serialNumber, tostring(result.value.characterId)))
        Notify(targetSource,
            ("Received %s (%s)"):format(result.value.definitionId, result.value.serialNumber), 4000)
        TriggerClientEvent("Feather:Inventory:OpenInventory", targetSource, nil, "player")
    end, true)
end
