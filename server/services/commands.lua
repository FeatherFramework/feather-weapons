if Config.DevMode then
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
            if source > 0 then FeatherCore.Notify.RightNotify(source, message, 4000) end
            return
        end

        print(("[feather-weapons] granted definition=%s item=%s serial=%s character=%s")
            :format(result.value.definitionId, tostring(result.value.itemInstanceId),
                result.value.serialNumber, tostring(result.value.characterId)))
        FeatherCore.Notify.RightNotify(targetSource,
            ("Received %s (%s)"):format(result.value.definitionId, result.value.serialNumber), 4000)
        TriggerClientEvent("Feather:Inventory:OpenInventory", targetSource, nil, "player")
    end, true)
end