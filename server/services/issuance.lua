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

function IssuanceService.Issue(context, request)
    context = type(context) == "table" and context or {}
    request = type(request) == "table" and request or {}
    local characterId = CoreAdapter.NormalizeCharacterId(request.characterId or context.characterId)
    local definitionId = CleanText(request.definitionId, 64)
    if not characterId or not definitionId then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID,
            "A target character and weapon definition are required", nil, context.correlationId)
    end

    local definitionResult = DefinitionRegistry.Get("weapon", definitionId)
    if not definitionResult.ok then return definitionResult end
    local definition = definitionResult.value
    local serialNumber = NextSerial(definition)
    if not serialNumber then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            "A unique weapon serial could not be generated", nil, context.correlationId)
    end

    context.characterId = characterId
    context.reason = CleanText(context.reason or "weapon_issuance", 64)
    context.resource = CleanText(context.resource or "feather-weapons", 64)
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

    return WeaponResult.Ok({
        itemInstanceId = created.value.instanceId,
        inventoryId = created.value.inventoryId,
        revision = created.value.revision,
        characterId = characterId,
        definitionId = definition.id,
        itemName = definition.itemName,
        serialNumber = serialNumber,
        metadata = metadataResult.value
    }, context.correlationId)
end
