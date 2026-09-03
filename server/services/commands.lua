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
            {
                name = "current session resolved",
                passed = session.ok == true,
                detail = targetSource and ("source=" .. tostring(targetSource)) or "no player"
            },
            {
                name = "character id accepted",
                passed = session.ok == true
                    and CoreAdapter.NormalizeCharacterId(session.value.characterId) == session.value.characterId
            },
            {
                name = "session is current",
                passed = session.ok == true
                    and CoreAdapter.IsSessionCurrent(targetSource, session.value.sessionId, session.value.characterId)
            },
            {
                name = "inventory identity mode",
                passed = type(inventoryCapabilities) == "table"
                    and type(inventoryCapabilities.characterIdentity) == "table"
                    and inventoryCapabilities.characterIdentity.uuid == true
                    and inventoryCapabilities.characterIdentity.mode == expectedMode,
                detail = "mode=" .. tostring(expectedMode)
            }
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

RegisterCommand("WeaponRuntimeLeaseSmokeTest", function(source, args)
        if source ~= 0 then return end
        local targetSource = tonumber(args and args[1])
        if not targetSource then
            local players = GetPlayers()
            targetSource = players[1] and tonumber(players[1]) or nil
        end
        local runtime = targetSource and WeaponRuntime.Get(targetSource) or nil
        local equipped = runtime and runtime.equipped or nil
        local sessionId = runtime and runtime.sessionId or nil
        local tests = {
            { name = "active equipped lease", passed = equipped ~= nil },
            {
                name = "current lease accepted",
                passed = equipped ~= nil and WeaponRuntime.MatchesLease(
                    targetSource, sessionId, equipped.itemInstanceId, equipped.generation)
            },
            {
                name = "stale generation rejected",
                passed = equipped ~= nil and not WeaponRuntime.MatchesLease(
                    targetSource, sessionId, equipped.itemInstanceId, (equipped.generation or 0) - 1)
            },
            {
                name = "foreign item rejected",
                passed = equipped ~= nil and not WeaponRuntime.MatchesLease(
                    targetSource, sessionId, "foreign-item", equipped.generation)
            },
            {
                name = "foreign session rejected",
                passed = equipped ~= nil and not WeaponRuntime.MatchesLease(
                    targetSource, "foreign-session", equipped.itemInstanceId, equipped.generation)
            }
        }
        local passed = 0
        for _, test in ipairs(tests) do
            if test.passed then passed = passed + 1 end
            print(("[WeaponRuntimeLeaseSmokeTest] %-27s %s"):format(
                test.name, test.passed and "PASS" or "FAIL"))
        end
        print(("[WeaponRuntimeLeaseSmokeTest] done %d/%d passed source=%s generation=%s"):format(
            passed, #tests, tostring(targetSource), tostring(equipped and equipped.generation)))
    end, true)

RegisterCommand("WeaponDualSlotContractSmokeTest", function(source, args)
        if source ~= 0 then return end
        local targetSource = tonumber(args and args[1])
        if not targetSource then
            local players = GetPlayers()
            targetSource = players[1] and tonumber(players[1]) or nil
        end
        local runtime = targetSource and WeaponRuntime.Get(targetSource) or nil
        local primary = runtime and runtime.slots and runtime.slots.primary or nil
        local offhand = runtime and runtime.slots and runtime.slots.offhand or nil
        local sessionId = runtime and runtime.sessionId or nil
        local capabilities = WeaponAPI.GetCapabilities()
        local tests = {
            {
                name = "named slot persistence",
                passed = Config.Inventory.equipmentSlots
                    and Config.Inventory.equipmentSlots.primary == Config.Inventory.equipmentSlot
                    and Config.Inventory.equipmentSlots.offhand ~= Config.Inventory.equipmentSlots.primary
            },
            {
                name = "slot runtime initialized",
                passed = runtime ~= nil and type(runtime.slots) == "table"
            },
            {
                name = "primary compatibility alias",
                passed = runtime ~= nil and runtime.equipped == primary
            },
            {
                name = "slot capability reported",
                passed = capabilities.features.namedEquipmentSlots == true
                    and capabilities.features.dualWield == true
                    and capabilities.features.offhandEnabled == true
                    and capabilities.features.matchingHashDualWield == true
            },
            {
                name = "pair ammo capability",
                passed = capabilities.features.pairAmmoEscrow == true
                    and capabilities.features.pairUnload == true
            },
            {
                name = "restore holster capability",
                passed = capabilities.features.restoredWeaponsHolstered == true
            },
            {
                name = "offhand policy configured",
                passed = capabilities.features.offhandPolicy == true
                    and EquipService.ValidateConfiguration().ok == true
            },
            {
                name = "slot repair capability",
                passed = capabilities.features.slotRepair == true
            },
            {
                name = "slot attachment capability",
                passed = capabilities.features.slotAttachments == true
            },
            {
                name = "atomic pair persistence",
                passed = capabilities.inventory.contractVersion >= 4
                    and capabilities.inventory.features
                    and capabilities.inventory.features.atomicBatchMetadata == true
                    and capabilities.inventory.features.atomicEquipmentPromotion == true
            },
            {
                name = "distinct weapon catalog",
                passed = capabilities.definitions.weapon >= 2
                    and DefinitionRegistry.Get("weapon", "revolver_cattleman").ok == true
                    and DefinitionRegistry.Get("weapon", "revolver_schofield").ok == true
            },
            {
                name = "slot item identities distinct",
                passed = not offhand or (primary ~= nil
                    and tostring(primary.itemInstanceId) ~= tostring(offhand.itemInstanceId))
            },
            {
                name = "primary lease scoped",
                passed = not primary or (targetSource ~= nil and sessionId ~= nil
                    and WeaponRuntime.MatchesLease(targetSource, sessionId,
                        primary.itemInstanceId, primary.generation, "primary"))
            },
            {
                name = "offhand lease scoped",
                passed = not offhand or (targetSource ~= nil and sessionId ~= nil
                    and WeaponRuntime.MatchesLease(targetSource, sessionId,
                        offhand.itemInstanceId, offhand.generation, "offhand"))
            }
        }
        local passed = 0
        for _, test in ipairs(tests) do
            if test.passed then passed = passed + 1 end
            print(("[WeaponDualSlotContractSmokeTest] %-29s %s"):format(
                test.name, test.passed and "PASS" or "FAIL"))
        end
        print(("[WeaponDualSlotContractSmokeTest] done %d/%d passed source=%s primary=%s offhand=%s")
            :format(passed, #tests, tostring(targetSource),
                tostring(primary and primary.itemInstanceId), tostring(offhand and offhand.itemInstanceId)))
    end, true)

if Config.DevMode then
    RegisterCommand("grantweapon", function(source, args)
        local definitionId = args[1] or "revolver_cattleman"
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

RegisterCommand("WeaponMetadataInspect", function(source, args)
    if source ~= 0 then return end
    local targetSource = tonumber(args and args[1])
    if not targetSource then
        print("[WeaponMetadataInspect] usage: WeaponMetadataInspect [serverId]")
        return
    end
    local result = ReconciliationService.InspectMetadata(targetSource)
    if not result.ok then
        print(("[WeaponMetadataInspect] FAIL code=%s message=%s"):format(
            tostring(result.error and result.error.code), tostring(result.error and result.error.message)))
        return
    end
    local value = result.value
    if not value.equipped then
        print(("[WeaponMetadataInspect] PASS source=%s equipped=false character=%s"):format(
            tostring(targetSource), tostring(value.characterId)))
        return
    end
    for _, slot in ipairs({ "primary", "offhand" }) do
        local item = value.slots and value.slots[slot] or nil
        print(("[WeaponMetadataInspect] PASS source=%s slot=%s equipped=%s item=%s definition=%s serial=%s generation=%s total=%s loaded=%s reserve=%s condition=%s attachments=%s runtimeMatch=%s")
        :format(
            tostring(targetSource), slot, tostring(item ~= nil),
            tostring(item and item.itemInstanceId), tostring(item and item.definitionId),
            tostring(item and item.serialNumber), tostring(item and item.generation),
            tostring(item and ((tonumber(item.loaded) or 0) + (tonumber(item.reserve) or 0))),
            tostring(item and item.loaded), tostring(item and item.reserve),
            tostring(item and item.condition), tostring(item and #(item.attachments or {})),
            tostring(item and item.runtimeMatches or false)))
    end
end, true)

RegisterCommand("WeaponReconcile", function(source, args)
    if source ~= 0 then return end
    local targetSource = tonumber(args and args[1])
    if not targetSource then
        print("[WeaponReconcile] usage: WeaponReconcile [serverId]")
        return
    end
    local result = ReconciliationService.Force(targetSource)
    if not result.ok then
        print(("[WeaponReconcile] FAIL code=%s message=%s"):format(
            tostring(result.error and result.error.code), tostring(result.error and result.error.message)))
        return
    end
    for _, slot in ipairs({ "primary", "offhand" }) do
        local equipped = result.value.slots and result.value.slots[slot] or nil
        print(("[WeaponReconcile] PASS source=%s slot=%s equipped=%s item=%s generation=%s total=%s loaded=%s reserve=%s condition=%s"):format(
            tostring(targetSource), slot, tostring(equipped ~= nil),
            tostring(equipped and equipped.itemInstanceId),
            tostring(equipped and equipped.generation), tostring(equipped and equipped.ammo),
            tostring(equipped and equipped.loaded), tostring(equipped and equipped.reserve),
            tostring(equipped and equipped.condition)))
    end
end, true)

RegisterCommand("WeaponReleaseContractSmokeTest", function(source, args)
        if source ~= 0 then return end
        local targetSource = tonumber(args and args[1])
        if not targetSource then
            local players = GetPlayers()
            targetSource = players[1] and tonumber(players[1]) or nil
        end
        local capabilities = WeaponAPI.GetCapabilities()
        local routesResult = exports["feather-core"]:GetRpcRoutes()
        local routes = {}
        if type(routesResult) == "table" and routesResult.ok == true then
            for _, route in ipairs(routesResult.value or {}) do routes[route.route] = true end
        end
        local metadata = targetSource and ReconciliationService.InspectMetadata(targetSource) or nil
        local tests = {
            {
                name = "definitions ready",
                passed = capabilities.ready == true
                    and capabilities.definitions.weapon == 2
                    and capabilities.definitions.ammunition == 1
                    and capabilities.definitions.attachment == 1,
                detail = ("weapon=%s ammunition=%s attachment=%s"):format(
                    tostring(capabilities.definitions.weapon),
                    tostring(capabilities.definitions.ammunition),
                    tostring(capabilities.definitions.attachment))
            },
            { name = "inventory ready",      passed = capabilities.inventory.ready == true },
            {
                name = "native reload surface",
                passed = capabilities.features.nativeReload == true
                    and capabilities.features.ammoEscrow == true
                    and capabilities.features.pairAmmoEscrow == true
                    and capabilities.features.pairUnload == true
                    and capabilities.features.reload == nil
            },
            {
                name = "runtime routes present",
                passed = routes["feather-weapons:equip:request"] == true
                    and routes["feather-weapons:ammo:sync"] == true
                    and routes["feather-weapons:ammo:pairSync"] == true
                    and routes["feather-weapons:ammo:unload"] == true
                    and routes["feather-weapons:repair:select"] == true
            },
            {
                name = "attachment routes present",
                passed = routes["feather-weapons:attachment:install"] == true
                    and routes["feather-weapons:attachment:remove"] == true
            },
            { name = "legacy reload absent", passed = routes["feather-weapons:ammo:reload"] ~= true },
            {
                name = "native probe disabled",
                passed = Config.NativeProbe
                    and Config.NativeProbe.enabled ~= true
            },
            {
                name = "active metadata valid",
                passed = type(metadata) == "table"
                    and metadata.ok == true and metadata.value.equipped == true
                    and type(metadata.value.slots) == "table"
                    and metadata.value.slots.primary ~= nil
                    and metadata.value.slots.primary.runtimeMatches == true
                    and (metadata.value.slots.offhand == nil
                        or metadata.value.slots.offhand.runtimeMatches == true),
                detail = targetSource and ("source=" .. tostring(targetSource)) or "no player"
            }
        }
        local passed = 0
        for _, test in ipairs(tests) do
            if test.passed then passed = passed + 1 end
            print(("[WeaponReleaseContractSmokeTest] %-27s %s%s"):format(
                test.name, test.passed and "PASS" or "FAIL",
                test.detail and ("  -- " .. test.detail) or ""))
        end
        print(("[WeaponReleaseContractSmokeTest] done %d/%d passed"):format(passed, #tests))
end, true)
