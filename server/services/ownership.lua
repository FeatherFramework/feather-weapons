WeaponOwnershipService = {}
local diagnostics = { observed = 0, failed = 0, leaseViolations = 0, last = nil }

local function CleanText(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    return value:sub(1, maximum)
end

function WeaponOwnershipService.EvaluateAdministrativeHold(metadata)
    if type(metadata) ~= "table" or type(metadata.flags) ~= "table" then
        return false, "Weapon administrative state could not be verified."
    end
    if metadata.flags.evidence == true then
        return false, "This weapon is held as evidence and cannot be moved or removed."
    end
    if metadata.flags.disabled == true then
        return false, "This weapon is administratively disabled and cannot be moved or removed."
    end
    return true
end

function WeaponOwnershipService.HandleCommittedMove(payload)
    if type(payload) ~= "table" then return nil end
    if tostring(payload.fromInventoryId) == tostring(payload.toInventoryId) then return nil end
    local definitionId = InventoryAdapter.ResolveWeaponDefinitionId(payload.definitionId)
    if not definitionId then return nil end

    local instance = InventoryAdapter.GetInstance({ correlationId = payload.correlationId }, payload.instanceId)
    if not instance.ok then
        diagnostics.failed = diagnostics.failed + 1
        print(("[feather-weapons] ownership observation failed item=%s code=%s"):format(
            tostring(payload.instanceId), tostring(instance.error and instance.error.code)))
        return instance
    end

    local metadata = instance.value.metadata or {}
    if metadata.weaponDefinitionId ~= definitionId then
        diagnostics.failed = diagnostics.failed + 1
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID,
            "Moved weapon metadata does not match its Inventory definition", {
                itemInstanceId = payload.instanceId,
                expectedDefinitionId = definitionId,
                actualDefinitionId = metadata.weaponDefinitionId
            }, payload.correlationId)
    end

    local fact = {
        operation = "inventory_move",
        outcome = "committed",
        itemInstanceId = tonumber(payload.instanceId),
        definitionId = definitionId,
        serialNumber = metadata.serialNumber,
        revision = tonumber(payload.revision) or instance.value.metadataRevision,
        fromInventoryId = tonumber(payload.fromInventoryId),
        toInventoryId = tonumber(payload.toInventoryId),
        actorSource = tonumber(payload.actorSource),
        actorCharacterId = CoreAdapter.NormalizeCharacterId(payload.actorCharacterId),
        reason = CleanText(payload.reason or "inventory_move", 64),
        resource = CleanText(payload.resource or "feather-inventory", 64),
        correlationId = CleanText(payload.correlationId, 128),
        occurredAt = tonumber(payload.occurredAt) or os.time()
    }

    local source, slot = WeaponRuntime.FindLeaseByItem(payload.instanceId)
    fact.activeLeaseViolation = source ~= nil
    if source then
        diagnostics.leaseViolations = diagnostics.leaseViolations + 1
        fact.activeSource = source
        fact.activeSlot = slot
        print(("[feather-weapons] CRITICAL equipped weapon moved item=%s source=%s slot=%s from=%s to=%s"):format(
            tostring(payload.instanceId), tostring(source), tostring(slot),
            tostring(payload.fromInventoryId), tostring(payload.toInventoryId)))
        if ReconciliationService then ReconciliationService.Force(source) end
    end

    TriggerEvent("Feather:Weapons:OwnershipTransitionCommitted", fact)
    diagnostics.observed = diagnostics.observed + 1
    diagnostics.last = fact
    if Config.DevMode then
        print(("[feather-weapons] ownership transition item=%s serial=%s definition=%s from=%s to=%s reason=%s"):format(
            tostring(fact.itemInstanceId), tostring(fact.serialNumber), tostring(fact.definitionId),
            tostring(fact.fromInventoryId), tostring(fact.toInventoryId), tostring(fact.reason)))
    end
    return WeaponResult.Ok(fact, payload.correlationId)
end

function WeaponOwnershipService.GetDiagnostics()
    return {
        observed = diagnostics.observed,
        failed = diagnostics.failed,
        leaseViolations = diagnostics.leaseViolations,
        last = diagnostics.last
    }
end

AddEventHandler("Feather:Inventory:ItemMoved", function(payload)
    WeaponOwnershipService.HandleCommittedMove(payload)
end)
