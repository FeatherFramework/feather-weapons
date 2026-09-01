AttachmentService = {}

local function Context(source, rpcContext, reason)
    return {
        actorSource = source,
        actorCharacterId = rpcContext.characterId,
        characterId = rpcContext.characterId,
        sessionId = rpcContext.sessionId,
        correlationId = rpcContext.correlationId,
        reason = reason,
        resource = "feather-weapons"
    }
end

local function Equipped(source, rpcContext)
    local runtime = WeaponRuntime.Get(source)
    if not runtime or runtime.sessionId ~= rpcContext.sessionId or not runtime.equipped then
        return nil, WeaponResult.Error(WeaponErrors.NOT_EQUIPPED, "Equip a weapon before modifying it", nil,
            rpcContext.correlationId)
    end
    return runtime.equipped
end

local function AtGunsmithStation(source, rpcContext)
    local settings = Config.Attachments or {}
    if settings.requireStation ~= true then return WeaponResult.Ok(true, rpcContext.correlationId) end
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Unable to verify gunsmith location", nil,
            rpcContext.correlationId)
    end
    local position = GetEntityCoords(ped)
    local tolerance = tonumber(settings.serverTolerance) or 3.0
    for stationId, station in pairs(settings.stations or {}) do
        local coords = station.coords
        if coords then
            local dx, dy, dz = position.x - coords.x, position.y - coords.y, position.z - coords.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= tolerance then
                return WeaponResult.Ok({ stationId = stationId, label = station.label }, rpcContext.correlationId)
            end
        end
    end
    return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT,
        "Weapon attachments can only be modified at a gunsmith bench", nil, rpcContext.correlationId)
end

local function ClientAttachments(metadata)
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

function AttachmentService.Install(source, rpcContext, attachmentId)
    local equipped, failure = Equipped(source, rpcContext)
    if not equipped then return failure end
    local station = AtGunsmithStation(source, rpcContext)
    if not station.ok then return station end
    local attachmentResult = DefinitionRegistry.Get("attachment", attachmentId)
    if not attachmentResult.ok then return attachmentResult end
    local attachment = attachmentResult.value
    if not DefinitionRegistry.IsAttachmentCompatible(equipped.definitionId, attachment.id) then
        return WeaponResult.Error(WeaponErrors.ITEM_INVALID, "Attachment is not compatible with the equipped weapon", {
            weaponId = equipped.definitionId, attachmentId = attachment.id
        }, rpcContext.correlationId)
    end

    local context = Context(source, rpcContext, "attachment_install")
    local transaction = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(equipped.itemInstanceId)
        if not item then
            return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Equipped weapon is no longer owned", nil,
                context.correlationId)
        end
        local weaponResult = DefinitionRegistry.Get("weapon", equipped.definitionId)
        if not weaponResult.ok then return weaponResult end
        local metadata = item.metadata
        local validated = WeaponMetadata.Validate(metadata, weaponResult.value, context.correlationId)
        if not validated.ok then return validated end
        for _, installed in ipairs(metadata.attachments) do
            if installed.definitionId == attachment.id then
                return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Attachment is already installed", nil,
                    context.correlationId)
            end
            if installed.slot == attachment.slot then
                return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "That attachment slot is already occupied", {
                    slot = attachment.slot, installed = installed.definitionId
                }, context.correlationId)
            end
        end
        if tx:GetQuantity(attachment.itemName) < 1 or not tx:RemoveQuantity(attachment.itemName, 1) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Required attachment item is unavailable", {
                itemName = attachment.itemName
            }, context.correlationId)
        end
        metadata.attachments[#metadata.attachments + 1] = { definitionId = attachment.id, slot = attachment.slot }
        local attachmentSet = DefinitionRegistry.ValidateAttachmentSet(equipped.definitionId, metadata.attachments)
        if not attachmentSet.ok then return attachmentSet end
        if not tx:SetMetadata(item.id, metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during installation", nil,
                context.correlationId)
        end
        return {
            itemInstanceId = item.id,
            attachmentId = attachment.id,
            installed = true,
            attachments = ClientAttachments(metadata)
        }
    end)
    if not transaction.ok then return transaction end
    WeaponRuntime.SetAttachments(source, rpcContext.sessionId, transaction.value.attachments, rpcContext.correlationId)
    return WeaponResult.Ok(transaction.value, rpcContext.correlationId)
end

function AttachmentService.Remove(source, rpcContext, attachmentId)
    local equipped, failure = Equipped(source, rpcContext)
    if not equipped then return failure end
    local station = AtGunsmithStation(source, rpcContext)
    if not station.ok then return station end
    local attachmentResult = DefinitionRegistry.Get("attachment", attachmentId)
    if not attachmentResult.ok then return attachmentResult end
    local attachment = attachmentResult.value
    if not attachment.removable then
        return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Attachment cannot be removed", nil,
            rpcContext.correlationId)
    end

    local context = Context(source, rpcContext, "attachment_remove")
    local transaction = InventoryAdapter.Transaction(context, function(tx)
        local item = tx:GetItemForUpdate(equipped.itemInstanceId)
        if not item then
            return WeaponResult.Error(WeaponErrors.ITEM_NOT_OWNED, "Equipped weapon is no longer owned", nil,
                context.correlationId)
        end
        local weaponResult = DefinitionRegistry.Get("weapon", equipped.definitionId)
        if not weaponResult.ok then return weaponResult end
        local metadata = item.metadata
        local validated = WeaponMetadata.Validate(metadata, weaponResult.value, context.correlationId)
        if not validated.ok then return validated end
        local found, remaining = false, {}
        for _, installed in ipairs(metadata.attachments) do
            if installed.definitionId == attachment.id then found = true else remaining[#remaining + 1] = installed end
        end
        if not found then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Attachment is not installed", nil,
                context.correlationId)
        end
        if not tx:AddQuantity(attachment.itemName, 1) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Inventory cannot accept the removed attachment",
                {
                    itemName = attachment.itemName
                }, context.correlationId)
        end
        metadata.attachments = remaining
        if not tx:SetMetadata(item.id, metadata, item.metadataRevision) then
            return WeaponResult.Error(WeaponErrors.OPERATION_CONFLICT, "Weapon metadata changed during removal", nil,
                context.correlationId)
        end
        return {
            itemInstanceId = item.id,
            attachmentId = attachment.id,
            installed = false,
            attachments = ClientAttachments(metadata)
        }
    end)
    if not transaction.ok then return transaction end
    WeaponRuntime.SetAttachments(source, rpcContext.sessionId, transaction.value.attachments, rpcContext.correlationId)
    return WeaponResult.Ok(transaction.value, rpcContext.correlationId)
end

FeatherCore.RPC.Register("feather-weapons:attachment:install", function(params, respond, source, context)
    respond(AttachmentService.Install(source, context, params and params.attachmentId))
end, { requireCharacter = true, windowMs = 2000, maxCalls = 3, maxPayloadBytes = 256 })

FeatherCore.RPC.Register("feather-weapons:attachment:remove", function(params, respond, source, context)
    respond(AttachmentService.Remove(source, context, params and params.attachmentId))
end, { requireCharacter = true, windowMs = 2000, maxCalls = 3, maxPayloadBytes = 256 })
