IssuanceService = {}

local serialCounter = 0
local reservedSerials = {}
local nativeTickets={}
local nativeRequests={}
local nativeSequence=0
local function clone(value)
    if type(value)~='table' then return value end
    local out={}; for k,v in pairs(value) do out[k]=clone(v) end; return out
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
function IssuanceService.NativeAvailable()
    local enabled=Config.DevMode==true and Config.NativeAlphaRuntime==true
        and Config.CharacterAmmunitionEnabled==true and Config.CharacterAmmoTransportEnabled==true
        and type(GetConvarInt)=='function' and GetConvarInt('feather_native_issuance',0)==1
        and GetResourceState('feather-weapons-native-proof')=='stopped'
        and WeaponNativeEnrollment.Validate(Config)~=nil
        and WeaponCharacterAmmoInventoryProvider.Status()=='ready' and WeaponProvenanceService.IsReady()==true
    if not enabled then return false end
    local called,contract=pcall(function() return exports['feather-inventory']:GetNativeIssuanceContract() end)
    return called and type(contract)=='table' and contract.contractVersion==1 and contract.ready==true
end
local function nativeCurrent(context)
    if not IssuanceService.NativeAvailable() or not WeaponNativeEnrollment.Allows(Config,context.characterId)
        or not CoreAdapter.IsSessionCurrent(context.targetSource,context.sessionId,context.characterId)
        or (WeaponNativeEquipmentBindings and WeaponNativeEquipmentBindings.IsStopping(context.targetSource)) then return false end
    local state=WeaponCharacterAmmoDispatcher.Status(context.targetSource)
    return state and state.phase=='active' and not state.busy and state.identity
        and state.identity.characterId==context.characterId and state.identity.sessionId==context.sessionId
        and state.identity.epoch==context.epoch or false
end
if type(exports)=='table' or type(exports)=='function' then
    exports('ValidateNativeIssuance',function(context,spec)
        if GetInvokingResource()~='feather-inventory' or type(context)~='table' then return false end
        local ticket=nativeTickets[context.ticket]
        return ticket~=nil and equal(ticket.context,context) and equal(ticket.spec,spec) and nativeCurrent(context)==true
    end)
end

local function CleanText(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    return value:sub(1, maximum)
end

local function ValidateRequestId(value)
    if type(value) ~= "string" or #value < 1 or #value > 128 then return nil end
    if not value:match("^[A-Za-z0-9][A-Za-z0-9._:%-]*$") then return nil end
    return value
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

local function BuildIssuedValue(item, definition, characterId)
    return {
        itemInstanceId = tonumber(item.id),
        inventoryId = tonumber(item.inventoryId),
        revision = tonumber(item.metadataRevision),
        characterId = characterId,
        definitionId = definition.id,
        itemName = definition.itemName,
        serialNumber = item.metadata.serialNumber,
        metadata = item.metadata
    }
end

local function RecordIssuance(value, context, recovered)
    local existing = WeaponProvenanceService.FindIssuanceEvent(
        value.itemInstanceId, context.correlationId)
    if not existing.ok then return existing end -- unknown read is not evidence of no prior event
    if existing.ok and existing.value.eventId then
        value.provenanceEventId = existing.value.eventId
        return existing
    end
    local recorded = WeaponProvenanceService.Record({
        operation = 'issue', transitionType = 'issuance', outcome = 'committed',
        itemInstanceId = value.itemInstanceId, definitionId = value.definitionId,
        serialNumber = value.serialNumber, revision = value.revision,
        toInventoryId = value.inventoryId, toCharacterId = value.characterId,
        actorSource = context.actorSource, actorCharacterId = context.actorCharacterId,
        reason = context.reason, resource = context.resource,
        correlationId = context.correlationId, occurredAt = os.time(),
        metadata = value.metadata, recovered = recovered == true
    })
    value.provenanceEventId = recorded.ok and recorded.value.eventId or nil
    return recorded
end

local function RecoverPending(context, requestId, definition, characterId, reservationId)
    local listed = InventoryAdapter.ListWeaponsForCharacter({
        characterId = characterId, correlationId = context.correlationId
    })
    if not listed.ok then return listed end
    local matches = {}
    for _, item in ipairs(listed.value or {}) do
        local metadata = type(item.metadata) == 'table' and item.metadata or {}
        local provenance = type(metadata.provenance) == 'table' and metadata.provenance or {}
        if metadata.weaponDefinitionId == definition.id
            and provenance.resource == context.resource
            and provenance.reference == requestId
            and CoreAdapter.NormalizeCharacterId(provenance.issuedToCharacterId) == characterId then
            matches[#matches + 1] = item
        end
    end
    if #matches ~= 1 then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            'Pending issuance could not be recovered unambiguously', {
                requestId = requestId, matches = #matches
            }, context.correlationId)
    end
    local valid = WeaponMetadata.Validate(matches[1].metadata, definition, context.correlationId)
    if not valid.ok then return valid end
    local value = BuildIssuedValue(matches[1], definition, characterId)
    local recorded = RecordIssuance(value, context, true)
    if not recorded.ok then return recorded end
    local committed = WeaponProvenanceService.CommitIssuance(
        reservationId, value, context.correlationId)
    if not committed.ok then
        local replay = WeaponProvenanceService.BeginIssuance(context.resource, requestId,
            context.reason, characterId, definition.id, context.correlationId)
        if replay.ok and replay.value.replayed == true then
            replay.value.recovered = true
            return WeaponResult.Ok(replay.value, context.correlationId)
        end
        return committed
    end
    value.replayed = true
    value.recovered = true
    return WeaponResult.Ok(value, context.correlationId)
end

local function IssueNative(context,request,definition,requestId)
    local function refused(message) return WeaponResult.Error(WeaponErrors.ITEM_INVALID,message,nil,context.correlationId) end
    if not requestId then return refused('Native issuance requires a stable requestId for every purpose.') end
    if not IssuanceService.NativeAvailable() then return refused('Scoped native issuance is disabled or unavailable.') end
    -- Initial contract is pristine firearms only, with no item-owned ammo or customization.
    if (request.condition~=nil and request.condition~=100) or (request.quality~=nil and request.quality~=100)
        or request.loadedAmmo~=nil or request.reserveAmmo~=nil or request.ammo~=nil
        or request.attachments~=nil or request.cosmetics~=nil then return refused('Native issuance currently requires a pristine, uncustomized firearm without ammunition.') end
    if request.provenance~=nil and type(request.provenance)~='table' then return refused('Native provenance must be a table.') end
    local supplied=request.provenance or {}
    for key in pairs(supplied) do if key~='type' and key~='reference' then return refused('Unsupported native provenance field.') end end
    local provenanceType=CleanText(supplied.type or context.reason,48)
    local provenanceReference=CleanText(supplied.reference,128)
    local registry=WeaponCharacterAmmoPolicy.Build(WeaponDefinitionCatalog)
    if not registry or not registry.weapons[definition.id] then return refused('Weapon is not admitted by the native firearm policy.') end
    local target,bound
    for _,raw in ipairs(GetPlayers()) do
        local source=tonumber(raw)
        local session=CoreAdapter.ResolveSession(source)
        if session and session.ok and session.value.characterId==context.characterId then
            if target then return refused('Target character session is ambiguous.') end
            target=source
            local state=WeaponCharacterAmmoDispatcher.Status(source)
            bound=state and state.identity
        end
    end
    local authority={targetSource=target,characterId=context.characterId,sessionId=bound and bound.sessionId,
        epoch=bound and bound.epoch}
    if not target or not nativeCurrent(authority) then return refused('A current active enrolled native target is required.') end
    local serial=NextSerial(definition)
    if not serial then return refused('Weapon serial allocation failed.') end
    local built=WeaponMetadata.Build(definition,{serialNumber=serial,condition=100,quality=100,
        provenance={type=provenanceType,reference=requestId,sourceReference=provenanceReference,resource=context.resource,
            issuedByCharacterId=CoreAdapter.NormalizeCharacterId(context.actorCharacterId),
            issuedToCharacterId=context.characterId,createdAt=os.time()}})
    if not built.ok then return built end
    built.value.ammo={ownership='character',type=definition.ammunitionType}
    local valid=WeaponMetadata.Validate(built.value,definition,context.correlationId)
    if not valid.ok then return valid end
    -- Canonical payload only: serial/time/session are outcomes, not replay keys.
    local fingerprint=json.encode({'native-firearm-v1',context.characterId,definition.id,context.reason,
        CoreAdapter.NormalizeCharacterId(context.actorCharacterId) or '',100,100,provenanceType,provenanceReference or ''})
    if #fingerprint>300 then return refused('Native issuance identity exceeds receipt bounds.') end
    nativeSequence=nativeSequence+1
    authority.ticket=('native-issue:%s:%s'):format(GetGameTimer(),nativeSequence)
    local spec={resource=context.resource,requestId=requestId,fingerprint=fingerprint,definitionId=definition.id,
        itemName=definition.itemName,metadata=valid.value}
    nativeTickets[authority.ticket]={context=clone(authority),spec=clone(spec)}
    local called,created=pcall(function() return exports['feather-inventory']:IssueNativeFirearmOnce(authority,spec) end)
    nativeTickets[authority.ticket]=nil
    if not called then return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
        'Native issuance outcome uncertain; retain the requestId and inspect before retrying.',nil,context.correlationId) end
    if not created or not created.ok then return created or refused('Native issuance returned no confirmed result.') end
    local value=created.value
    if type(value)~='table' or value.characterId~=context.characterId or value.definitionId~=definition.id then
        return refused('Native issuance result mismatch; do not grant a replacement.')
    end
    local checked=WeaponCharacterAmmoItem.Validate(value.metadata,definition)
    if not checked then return refused('Committed native issuance metadata is invalid; inspect receipt, do not replace.') end
    if value.replayed then reservedSerials[serial]=nil end
    local recorded=RecordIssuance(value,context,value.replayed==true)
    if not recorded.ok then return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
        'Firearm delivery committed; provenance incomplete. Retain requestId; do not issue a replacement.',
        {itemInstanceId=value.itemInstanceId},context.correlationId) end
    return WeaponResult.Ok(value,context.correlationId)
end

if type(RegisterCommand)=='function' then
RegisterCommand('WeaponNativeIssuanceStatus',function(source)
    if source~=0 then return end
    print('[WeaponNativeIssuanceStatus] '..json.encode({available=IssuanceService.NativeAvailable(),
        pristineOnly=true,stableRequestIdRequired=true,noGrants=true}))
end,true)
RegisterCommand('WeaponNativeIssue',function(source,args)
    if source~=0 or not IssuanceService.NativeAvailable() then return end
    local target=tonumber(args and args[1])
    if not args or #args~=3 or not target or target<1 or target%1~=0 then
        return print('[WeaponNativeIssue] REFUSED current-server-id definition-id stable-request-id required')
    end
    local session=CoreAdapter.ResolveSession(target)
    if not session or not session.ok then return print('[WeaponNativeIssue] REFUSED current target required') end
    local result=IssuanceService.Issue({characterId=session.value.characterId,resource='feather-weapons',
        reason='development_grant',correlationId=args[3]},
        {characterId=session.value.characterId,definitionId=args[2],requestId=args[3],purpose='development_grant'},'feather-weapons')
    print('[WeaponNativeIssue] '..(result and result.ok and 'PASS ' or 'REFUSED ')..json.encode(result)
        ..'; no equip/ammo/material grant requested; retain requestId')
end,true) end

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
    local requestId = ValidateRequestId(request.requestId)
    if request.requestId ~= nil and not requestId then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID,
            "requestId must be 1-128 characters using letters, numbers, dot, underscore, colon, or hyphen",
            nil, context.correlationId)
    end
    if Config.CharacterAmmunitionEnabled==true or Config.CharacterAmmoTransportEnabled==true then
        local key=tostring(context.resource)..'\0'..tostring(requestId)
        if nativeRequests[key] then return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            'Native issuance request is already in progress; do not submit a new requestId.',nil,context.correlationId) end
        nativeRequests[key]=true
        local called,result=pcall(IssueNative,clone(context),clone(request),definition,requestId)
        nativeRequests[key]=nil
        if not called then return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            'Native issuance outcome is unconfirmed; retain requestId and inspect before retrying.',nil,context.correlationId) end
        return result
    end
    if purpose ~= "development_grant" and not requestId then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID,
            "A stable requestId is required for this issuance purpose", nil, context.correlationId)
    end
    local reservationId
    if requestId then
        local begun = WeaponProvenanceService.BeginIssuance(context.resource, requestId, purpose,
            characterId, definitionId, context.correlationId)
        if not begun.ok then return begun end
        if begun.value.replayed == true then return WeaponResult.Ok(begun.value, context.correlationId) end
        reservationId = begun.value.reservationId
        if begun.value.pending == true then
            return RecoverPending(context, requestId, definition, characterId, reservationId)
        end
    end
    local function CancelReservation()
        if reservationId then WeaponProvenanceService.CancelIssuance(reservationId) end
    end
    local serialNumber = NextSerial(definition)
    if not serialNumber then
        CancelReservation()
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
        CancelReservation()
        return metadataResult
    end

    local created = InventoryAdapter.CreateWeapon(context, definition, metadataResult.value)
    if not created.ok then
        reservedSerials[serialNumber] = nil
        CancelReservation()
        return created
    end

    local value = BuildIssuedValue({
        id = created.value.instanceId, inventoryId = created.value.inventoryId,
        metadataRevision = created.value.revision, metadata = metadataResult.value
    }, definition, characterId)
    local recorded = RecordIssuance(value, context, false)
    if not recorded.ok then
        print(('[feather-weapons] CRITICAL issuance provenance failed item=%s serial=%s'):format(
            tostring(value.itemInstanceId), tostring(serialNumber)))
    end
    if Config.DevMode and context.resource == 'feather-weapons'
        and context.failureInjection == 'after_create' then
        WeaponProvenanceService.MarkIssuanceInterrupted(reservationId)
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
            'Injected failure after weapon creation', {
                itemInstanceId = value.itemInstanceId, serialNumber = value.serialNumber
            }, context.correlationId)
    end
    if reservationId then
        local committed = WeaponProvenanceService.CommitIssuance(reservationId, value, context.correlationId)
        if not committed.ok then return committed end
    end
    return WeaponResult.Ok(value, context.correlationId)
end

function IssuanceService.CheckContract()
    local untrusted = IssuanceService.Issue({ reason = "development_grant" }, {
        characterId = "00000000-0000-0000-0000-000000000001",
        definitionId = "revolver_cattleman", purpose = "development_grant"
    }, "untrusted-smoke-resource")
    local incomplete = IssuanceService.Issue({ reason = "development_grant" }, {}, "feather-weapons")
    local missingRequestId = IssuanceService.Issue({ reason = "purchase" }, {
        characterId = "00000000-0000-0000-0000-000000000001",
        definitionId = "revolver_cattleman", purpose = "purchase"
    }, "feather-weapons")
    local oversizedRequestId = IssuanceService.Issue({ reason = "purchase" }, {
        characterId = "00000000-0000-0000-0000-000000000001",
        definitionId = "revolver_cattleman", purpose = "purchase",
        requestId = string.rep("a", 129)
    }, "feather-weapons")
    local malformedRequestId = IssuanceService.Issue({ reason = "purchase" }, {
        characterId = "00000000-0000-0000-0000-000000000001",
        definitionId = "revolver_cattleman", purpose = "purchase",
        requestId = "invalid request id"
    }, "feather-weapons")
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
            and incomplete.error.code == WeaponErrors.ITEM_INVALID,
        requestIdRequired = not missingRequestId.ok and missingRequestId.error
            and missingRequestId.error.code == WeaponErrors.ITEM_INVALID,
        oversizedRequestIdRejected = not oversizedRequestId.ok and oversizedRequestId.error
            and oversizedRequestId.error.code == WeaponErrors.ITEM_INVALID,
        malformedRequestIdRejected = not malformedRequestId.ok and malformedRequestId.error
            and malformedRequestId.error.code == WeaponErrors.ITEM_INVALID
    }
end
