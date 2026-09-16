IssuanceService = {}

local serialCounter = 0
local reservedSerials = {}

local function CleanText(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    return value:sub(1, maximum)
end

local function NextSerial(definition)
    local family = tostring(definition.family or "weapon"):upper():gsub("[^A-Z0-9]", ""):sub(1, 4)
    if family == "" then family = "WPN" end
    for _ = 1, 16 do
        serialCounter = (serialCounter + 1) % 0x10000
        local serial = ("FW-%s-%08X-%06X-%04X"):format(
            family, os.time(), math.random(0, 0xFFFFFF), serialCounter)
        if not reservedSerials[serial] then
            reservedSerials[serial] = true
            return serial
        end
    end
    return nil
end

local function BuildProvenance(context, request)
    local supplied = type(request.provenance) == "table" and request.provenance or {}
    return {
        type = CleanText(supplied.type or context.reason or "issued", 48),
        reference = CleanText(supplied.reference, 128),
        resource = CleanText(context.resource or "feather-weapons", 64),
        issuedBySource = tonumber(context.actorSource),
        issuedByCharacterId = CoreAdapter.NormalizeCharacterId(context.actorCharacterId),
        issuedToCharacterId = CoreAdapter.NormalizeCharacterId(context.characterId),
        createdAt = os.time()
    }
end

local function Authorize(context, definitionId, purpose)
    local settings = Config.Issuance or {}
    if (settings.trustedResources or {})[context.resource] ~= true then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID,
            "Calling resource is not trusted for weapon issuance", nil, context.correlationId)
    end
    if (settings.allowedPurposes or {})[purpose] ~= true then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID,
            "Weapon issuance purpose is not allowed", { purpose = purpose }, context.correlationId)
    end
    local authorization = settings.authorization or {}
    if authorization.enabled ~= true then return WeaponResult.Ok(true, context.correlationId) end
    if not context.actorSource or type(authorization.action) ~= "string" or authorization.action == "" then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID,
            "Weapon issuance authorization is not configured", nil, context.correlationId)
    end
    local called, decision = pcall(function()
        return exports["feather-core"]:Authorize(authorization.action, {
            source = context.actorSource, correlationId = context.correlationId,
            subject = { operation = "issue", purpose = purpose,
                definitionId = definitionId, characterId = context.characterId }
        })
    end)
    if not called or type(decision) ~= "table" or not decision.ok
        or type(decision.value) ~= "table" or decision.value.allowed ~= true then
        return WeaponResult.Error(WeaponErrors.AUTHORIZATION_INVALID,
            "This character is not authorized to issue weapons", nil, context.correlationId)
    end
    return WeaponResult.Ok(true, context.correlationId)
end

function IssuanceService.Issue(context, request, invokingResource)
    context = type(context) == "table" and context or {}
    request = type(request) == "table" and request or {}
    local characterId = CoreAdapter.NormalizeCharacterId(request.characterId or context.characterId)
    local definitionId = CleanText(request.definitionId, 64)
    local purpose = CleanText(request.purpose or context.reason or "issued", 48)
    if not characterId or not definitionId then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID,
            "A target character and weapon definition are required", nil, context.correlationId)
    end

    local definitionResult = DefinitionRegistry.Get("weapon", definitionId)
    if not definitionResult.ok then return definitionResult end
    local definition = definitionResult.value
    context.characterId = characterId
    context.reason = purpose
    context.resource = CleanText(invokingResource or context.resource, 64)
    local authorized = Authorize(context, definitionId, purpose)
    if not authorized.ok then return authorized end
    local serialNumber = NextSerial(definition)
    if not serialNumber then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            "A unique weapon serial could not be generated", nil, context.correlationId)
    end

    context.correlationId = context.correlationId
        or ("issue:%s:%s:%s"):format(tostring(characterId), tostring(GetGameTimer()), tostring(serialCounter))

    local metadataResult = WeaponMetadata.Build(definition, {
        serialNumber = serialNumber,
        condition = request.condition,
        quality = request.quality,
        loadedAmmo = 0,
        chambered = false,
        provenance = BuildProvenance(context, request)
    })
    if not metadataResult.ok then
        reservedSerials[serialNumber] = nil
        return metadataResult
    end

    local created = InventoryAdapter.CreateWeapon(context, definition, metadataResult.value)
    if not created.ok then
        reservedSerials[serialNumber] = nil
        return created
    end

    local value = {
        itemInstanceId = created.value.instanceId,
        inventoryId = created.value.inventoryId,
        revision = created.value.revision,
        characterId = characterId,
        definitionId = definition.id,
        itemName = definition.itemName,
        serialNumber = serialNumber,
        metadata = metadataResult.value
    }
    local recorded = WeaponProvenanceService.Record({
        operation = 'issue', transitionType = 'issuance', outcome = 'committed',
        itemInstanceId = value.itemInstanceId, definitionId = definition.id,
        serialNumber = serialNumber, revision = value.revision,
        toInventoryId = value.inventoryId, toCharacterId = characterId,
        actorSource = context.actorSource, actorCharacterId = context.actorCharacterId,
        reason = context.reason, resource = context.resource,
        correlationId = context.correlationId, occurredAt = os.time(),
        metadata = metadataResult.value
    })
    value.provenanceEventId = recorded.ok and recorded.value.eventId or nil
    if not recorded.ok then
        print(('[feather-weapons] CRITICAL issuance provenance failed item=%s serial=%s'):format(
            tostring(value.itemInstanceId), tostring(serialNumber)))
    end
    return WeaponResult.Ok(value, context.correlationId)
end

function IssuanceService.CheckContract()
    local untrusted = IssuanceService.Issue({ reason = "development_grant" }, {
        characterId = "00000000-0000-0000-0000-000000000001",
        definitionId = "revolver_cattleman", purpose = "development_grant"
    }, "untrusted-smoke-resource")
    local incomplete = IssuanceService.Issue({ reason = "development_grant" }, {}, "feather-weapons")
    local settings, authorization = Config.Issuance or {}, (Config.Issuance or {}).authorization or {}
    return {
        serviceAvailable = type(IssuanceService.Issue) == "function",
        trustedCallerConfigured = (settings.trustedResources or {})["feather-weapons"] == true,
        purposeConfigured = (settings.allowedPurposes or {}).development_grant == true,
        authorizationConfigured = authorization.enabled ~= true
            or (type(authorization.action) == "string" and authorization.action ~= ""),
        untrustedRejected = not untrusted.ok and untrusted.error
            and untrusted.error.code == WeaponErrors.AUTHORIZATION_INVALID,
        incompleteRejected = not incomplete.ok and incomplete.error
            and incomplete.error.code == WeaponErrors.ITEM_INVALID
    }
end
