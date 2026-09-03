FeatherWeaponsClient = {}
local clientContract = 4
local equipped, offhand, pendingToken, pendingNativeWeaponName = nil, nil, nil, nil
local syncInFlight, desiredAmmo, desiredLoaded = false, nil, nil
local unloadInFlight, unloadQueued = false, false
local inventoryWeaponInFlight = false
local attachmentReconcileUntil = 0
local BeginUnload
local RegisterCharacterLogoutCheckpoint
local observerCorrectionPending = false
local checkpointWaiters = {}
local nativeRemoveReason = joaat('REMOVE_REASON_CLIENT_PURGED')
local pairSyncInFlight = false
local pairCheckpointPending = false
local pairObserved = nil
local pairConsumed = { primary = 0, offhand = 0 }
local offhandEntitlements = {}
local offhandRecoveryInFlight = false
local nativePairCopies = nil
local holsterSequence = 0

local function NativeTrue(value)
    return value == true or value == 1
end

local function RemoveNativePairCopies()
    if not nativePairCopies then return end

    FeatherGuidWeapons.Destroy(nativePairCopies)
    nativePairCopies = nil
end

local function PairNativeClips(primary, secondary)
    local ped = PlayerPedId()
    if primary.nativeWeaponName == secondary.nativeWeaponName then
        if not nativePairCopies then
            return false, 0, false, 0
        end

        local primaryOk, primaryLoaded = FeatherGuidWeapons.ReadClip(ped, nativePairCopies.primary)
        local offhandOk, offhandLoaded = FeatherGuidWeapons.ReadClip(ped, nativePairCopies.offhand)
        return primaryOk, primaryLoaded, offhandOk, offhandLoaded
    end

    local primaryOk, primaryLoaded = GetAmmoInClip(ped, joaat(primary.nativeWeaponName))
    local offhandOk, offhandLoaded = GetAmmoInClip(ped, joaat(secondary.nativeWeaponName))
    return NativeTrue(primaryOk), primaryLoaded, NativeTrue(offhandOk), offhandLoaded
end

local function AddOffhandEntitlement(itemName, slotId)
    local inventoryId = 1
    local itemHash = joaat(itemName)
    -- InventoryGetInventoryItemCountWithItemid
    local existing = math.max(0,
        math.floor(tonumber(Citizen.InvokeNative(0xE787F05DFC977BDE, inventoryId, itemHash, false)) or 0))
    if existing > 0 then return true end

    local characterGuid = FeatherGuidWeapons.ResolveGuid(inventoryId, nil, joaat('CHARACTER'), 0xA1212100)
    local wardrobeGuid = characterGuid and
        FeatherGuidWeapons.ResolveGuid(inventoryId, characterGuid, joaat('WARDROBE'), 0x3DABBFA7) or nil
    if not wardrobeGuid then return false end

    local itemGuid = FeatherGuidWeapons.NewBuffer(8 * 13)
    local added = Citizen.InvokeNative(0xCB5D11F9508A928D, -- InventoryAddItemWithGuid
        inventoryId,
        itemGuid,
        wardrobeGuid,
        itemHash,
        slotId,
        1,
        joaat('ADD_REASON_DEFAULT')
    )
    if not NativeTrue(added) then return false end

    -- InventoryEquipItemWithGuid
    if not NativeTrue(Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemGuid, true)) then
        Citizen.InvokeNative(0x3E4E811480B3AE79, inventoryId, itemGuid, 1,
            joaat('REMOVE_REASON_DEFAULT'))
        return false
    end

    offhandEntitlements[#offhandEntitlements + 1] = {
        inventoryId = inventoryId,
        guid = itemGuid,
        itemName = itemName
    }
    return true
end

local function EnsureOffhandEntitlement()
    if not (Config.Offhand and Config.Offhand.provisionNativeEntitlement) then
        return NativeTrue(GetAllowDualWield(PlayerPedId()))
    end

    local provisioned = true
    for _, entitlement in ipairs(Config.Offhand.nativeEntitlements) do
        if not AddOffhandEntitlement(entitlement.itemName, entitlement.slotId) then
            provisioned = false
            break
        end
    end
    SetAllowDualWield(PlayerPedId(), true)
    return provisioned and NativeTrue(GetAllowDualWield(PlayerPedId()))
end

local function RemoveOffhandEntitlements()
    for index = #offhandEntitlements, 1, -1 do
        local value = offhandEntitlements[index]
        Citizen.InvokeNative(0x3E4E811480B3AE79, -- InventoryRemoveInventoryItemWithGuid
            value.inventoryId,
            value.guid,
            1,
            joaat('REMOVE_REASON_DEFAULT')
        )
    end
    offhandEntitlements = {}
end

local function RemoveNativeWeapon(ped, weaponHash)
    RemoveWeaponFromPed(ped, weaponHash, true, nativeRemoveReason)
end

local function ResolveCheckpointWaiters(result)
    local waiters = checkpointWaiters
    checkpointWaiters = {}
    for _, callback in ipairs(waiters) do
        callback(result)
    end
end

local function Notify(message)
    local called, result = pcall(function()
        return exports['feather-notify']:ShowNotification({
            style = 'right',
            message = message,
            duration = 3000
        })
    end)

    if not called then
        result = { ok = false, code = 'provider_unavailable' }
    end

    if (not result or result.ok ~= true) and Config.DevMode then
        print(('[feather-weapons] %s'):format(message))
    end
end

local function SameInstance(left, right)
    return left ~= nil and right ~= nil and tostring(left) == tostring(right)
end

local function SetNativeAmmo(nativeAmmoName, amount, nativeWeaponName, loaded)
    if not nativeAmmoName then return end

    local ped = PlayerPedId()
    local ammoHash = joaat(nativeAmmoName)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local before = GetPedAmmoByType(ped, ammoHash)
    if nativeWeaponName and loaded ~= nil then
        SetAmmoInClip(ped, joaat(nativeWeaponName), math.max(0, math.floor(tonumber(loaded) or 0)))
    end

    if before < amount then
        Citizen.InvokeNative(0x5FD1E1F011E76D7E, ped, ammoHash, amount) -- SetPedAmmoByType
    end

    if Config.DevMode then
        print(('[feather-weapons] native ammo target=%s before=%s after=%s'):format(
            tostring(amount), tostring(before), tostring(GetPedAmmoByType(ped, ammoHash))))
    end
end

local function ApplyNativeAttachments(nativeWeaponName, attachments)
    local ped = PlayerPedId()
    local weaponHash = joaat(nativeWeaponName)
    for _, attachment in ipairs(attachments or {}) do
        local componentHash = joaat(attachment.nativeComponentName)
        local modelHash = Citizen.InvokeNative(0x59DE03442B6C9598, componentHash) -- GetWeaponComponentTypeModel
        if modelHash and modelHash ~= 0 then
            RequestModel(modelHash, false)
            local attempts = 0
            while not HasModelLoaded(modelHash) and attempts < 100 do
                attempts = attempts + 1
                Wait(0)
            end
        end

        Citizen.InvokeNative(0x74C9090FDD1BB48E, ped, componentHash, weaponHash, true) -- GiveWeaponComponentToEntity

        if modelHash and modelHash ~= 0 then
            SetModelAsNoLongerNeeded(modelHash)
        end
    end
end

local function ScheduleAttachmentReconciliation(nativeWeaponName, attachments)
    if not attachments or #attachments == 0 then return end

    attachmentReconcileUntil = GetGameTimer() + 15000
    for _, delay in ipairs({ 250, 1000 }) do
        SetTimeout(delay, function()
            local expected = (equipped and equipped.nativeWeaponName == nativeWeaponName)
                or pendingNativeWeaponName == nativeWeaponName
            if expected then
                ApplyNativeAttachments(nativeWeaponName, attachments)
            end
        end)
    end
end

local function GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, loaded, attachments)
    local ped = PlayerPedId()
    local ammoHash = nativeAmmoName and joaat(nativeAmmoName) or nil
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local before = ammoHash and GetPedAmmoByType(ped, ammoHash) or nil
    GiveWeaponToPed(
        ped,
        joaat(nativeWeaponName),
        0,
        false,
        true,
        0,
        false,
        0.5,
        1.0,
        joaat('ADD_REASON_DEFAULT'),
        true,
        0.0,
        false
    )

    SetAmmoInClip(ped, joaat(nativeWeaponName), math.max(0, math.floor(tonumber(loaded) or 0)))
    if ammoHash then
        SetPedAmmoByType(ped, ammoHash, amount)
    end

    ApplyNativeAttachments(nativeWeaponName, attachments)
    ScheduleAttachmentReconciliation(nativeWeaponName, attachments)

    if Config.DevMode then
        local after = ammoHash and GetPedAmmoByType(ped, ammoHash) or nil
        print(('[feather-weapons] native weapon granted total=%s before=%s after=%s'):format(
            tostring(amount), tostring(before), tostring(after)))
    end
end

local function RestoreApprovedNativePair(primary, secondary)
    if not EnsureOffhandEntitlement() then
        return false, 'Offhand holster entitlement is unavailable.'
    end

    local ped = PlayerPedId()
    local primaryPoint = math.floor(tonumber(Config.Offhand.primaryAttachPoint) or 2)
    local offhandPoint = math.floor(tonumber(Config.Offhand.offhandAttachPoint) or 3)
    local primaryHash = joaat(primary.nativeWeaponName)
    local secondaryHash = joaat(secondary.nativeWeaponName)
    local identical = primaryHash == secondaryHash
    if identical then
        local created = FeatherGuidWeapons.CreateMatchingPair(ped, primary.nativeWeaponName)
        if not created.ok then
            return false, created.message
        end

        nativePairCopies = created.value
    else
        GiveWeaponToPed(ped, primaryHash, 0, true, false,
            primaryPoint, false, 0.5, 1.0, joaat('ADD_REASON_DEFAULT'), true, 0.0, false)

        GiveWeaponToPed(ped, secondaryHash, 0, true, false,
            offhandPoint, false, 0.5, 1.0, joaat('ADD_REASON_DEFAULT'), true, 0.0, false)
    end

    local primaryReady, secondaryReady = false, false
    if identical then
        SetPedAmmoByType(ped, joaat(primary.nativeAmmoName), primary.ammo + secondary.ammo)
        SetAllowDualWield(ped, true)
        Wait(1000)
        MakePedReload(ped)
        for _ = 1, 40 do
            primaryReady, _, secondaryReady = PairNativeClips(primary, secondary)
            if primaryReady and secondaryReady then break end
            Wait(50)
        end
    else
        for _ = 1, 40 do
            SetAmmoInClip(ped, primaryHash, primary.loaded)
            SetAmmoInClip(ped, secondaryHash, secondary.loaded)
            local primaryOk = GetAmmoInClip(ped, primaryHash)
            local secondaryOk = GetAmmoInClip(ped, secondaryHash)
            primaryReady, secondaryReady = NativeTrue(primaryOk), NativeTrue(secondaryOk)
            if primaryReady and secondaryReady then break end
            Wait(50)
        end
    end
    if not primaryReady or not secondaryReady then
        return false, 'Native weapon pair did not become ready.'
    end

    SetPedAmmoByType(ped, joaat(primary.nativeAmmoName), primary.ammo + secondary.ammo)
    ApplyNativeAttachments(primary.nativeWeaponName, primary.attachments)
    ApplyNativeAttachments(secondary.nativeWeaponName, secondary.attachments)

    if identical then
        FeatherGuidWeapons.Activate(ped, nativePairCopies)
        SetAllowDualWield(ped, true)
    else
        SetCurrentPedWeapon(ped, primaryHash, true, primaryPoint, false, false)
    end
    return true
end

local function NativePairAvailable(primary, secondary)
    if not NativeTrue(GetAllowDualWield(PlayerPedId())) then return false end

    local primaryOk, _, secondaryOk = PairNativeClips(primary, secondary)
    return primaryOk and secondaryOk
end

local function ResetNativeAmmo(reason, nativeAmmoName)
    if not (Config.Runtime and Config.Runtime.authoritativeNativeAmmo) then return end

    local ped = PlayerPedId()
    local before = nativeAmmoName and GetPedAmmoByType(ped, joaat(nativeAmmoName)) or nil
    Citizen.InvokeNative(0x1B83C0DEEBCBB214, ped) -- RemoveAllPedAmmo
    if Config.DevMode then
        local after = nativeAmmoName and GetPedAmmoByType(ped, joaat(nativeAmmoName)) or nil
        print(('[feather-weapons] native ammo reset reason=%s before=%s after=%s'):format(
            tostring(reason), tostring(before), tostring(after)))
    end
end

local function RestoreApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, loaded, attachments)
    RemoveNativeWeapon(PlayerPedId(), joaat(nativeWeaponName))
    ResetNativeAmmo('ammo-restored', nativeAmmoName)
    GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, loaded, attachments)
end

local function ClearNativeWeapon()
    local nativeWeaponName = equipped and equipped.nativeWeaponName or pendingNativeWeaponName
    local nativeAmmoName = equipped and equipped.nativeAmmoName or nil
    RemoveNativePairCopies()

    if nativeWeaponName then
        RemoveNativeWeapon(PlayerPedId(), joaat(nativeWeaponName))
    end

    if offhand and offhand.nativeWeaponName then
        RemoveNativeWeapon(PlayerPedId(), joaat(offhand.nativeWeaponName))
    end

    ResetNativeAmmo('weapon-cleared', nativeAmmoName)
    RemoveOffhandEntitlements()

    equipped, offhand, pendingToken, pendingNativeWeaponName, desiredAmmo, desiredLoaded, syncInFlight =
        nil, nil, nil, nil, nil, nil, false
    pairSyncInFlight, pairCheckpointPending, pairObserved = false, false, nil
    pairConsumed = { primary = 0, offhand = 0 }
    unloadInFlight, unloadQueued = false, false
    observerCorrectionPending = false
    ResolveCheckpointWaiters({ ok = false, code = 'session_cleared', message = 'Weapon session was cleared.' })
    attachmentReconcileUntil = 0
end

local function ApprovedState(approved)
    return {
        slot = approved.slot or 'primary',
        itemInstanceId = approved.itemInstanceId,
        definitionId = approved.definitionId,
        nativeWeaponName = approved.nativeWeaponName,
        nativeAmmoName = approved.nativeAmmoName,
        ammo = tonumber(approved.ammo) or 0,
        condition = tonumber(approved.condition),
        loaded = tonumber(approved.loaded) or 0,
        reserve = tonumber(approved.reserve) or 0,
        generation = tonumber(approved.generation),
        sessionId = approved.sessionId,
        attachments = approved.attachments or {}
    }
end

local function ApplyApprovedPair(primary, secondary)
    if equipped and offhand
        and SameInstance(equipped.itemInstanceId, primary.itemInstanceId)
        and SameInstance(offhand.itemInstanceId, secondary.itemInstanceId)
        and equipped.generation == tonumber(primary.generation)
        and offhand.generation == tonumber(secondary.generation)
        and NativePairAvailable(primary, secondary) then
        equipped, offhand = ApprovedState(primary), ApprovedState(secondary)
        return true
    end

    ClearNativeWeapon()
    equipped, offhand = ApprovedState(primary), ApprovedState(secondary)
    local restored, message = RestoreApprovedNativePair(equipped, offhand)
    if not restored then
        ClearNativeWeapon()
        return false, message
    end

    local primaryOk, primaryLoaded, offhandOk, offhandLoaded =
        PairNativeClips(equipped, offhand)
    pairObserved = {
        primary = primaryOk and math.max(0, math.floor(tonumber(primaryLoaded) or 0)) or 0,
        offhand = offhandOk and math.max(0, math.floor(tonumber(offhandLoaded) or 0)) or 0,
        total = math.max(0, math.floor(tonumber(GetPedAmmoByType(
            PlayerPedId(), joaat(equipped.nativeAmmoName))) or 0))
    }
    pairConsumed = { primary = 0, offhand = 0 }
    if Config.DevMode then
        print(('[feather-weapons] pair restored primary=%s/%s offhand=%s/%s total=%d loaded=%d/%d')
            :format(tostring(equipped.itemInstanceId), equipped.nativeWeaponName,
                tostring(offhand.itemInstanceId), offhand.nativeWeaponName,
                pairObserved.total, pairObserved.primary, pairObserved.offhand))
    end
    return true
end

local function ApplyApprovedWeapon(approved)
    local alreadyApplied = not offhand
        and ((equipped and SameInstance(equipped.itemInstanceId, approved.itemInstanceId))
            or (pendingNativeWeaponName == approved.nativeWeaponName)
        )
    if not alreadyApplied then
        ClearNativeWeapon()
        GiveApprovedNativeWeapon(approved.nativeWeaponName, approved.nativeAmmoName, approved.ammo, approved.loaded,
            approved.attachments)
    end

    equipped = ApprovedState(approved)
    desiredAmmo = equipped.ammo
    desiredLoaded = equipped.loaded
end

local function FlushConsumption()
    if syncInFlight then return end

    if not equipped then
        ResolveCheckpointWaiters({ ok = true, value = { skipped = true } })
        return
    end

    if desiredAmmo == nil or desiredAmmo > equipped.ammo then
        ResolveCheckpointWaiters({
            ok = false,
            code = 'invalid_native_state',
            message =
            'Native ammunition state is invalid.'
        })
        return
    end

    if desiredAmmo == equipped.ammo and desiredLoaded == equipped.loaded then
        ResolveCheckpointWaiters({
            ok = true,
            value = {
                total = equipped.ammo, loaded = equipped.loaded, reserve = equipped.reserve
            }
        })
        return
    end

    syncInFlight = true
    local submitted = desiredAmmo
    local submittedLoaded = desiredLoaded or (equipped.loaded or 0)
    local leaseItem = equipped.itemInstanceId
    local leaseGeneration = equipped.generation
    FeatherCore.RPC.Call('feather-weapons:ammo:sync', {
        total = submitted,
        loaded = submittedLoaded,
        itemInstanceId = leaseItem,
        generation = leaseGeneration
    }, function(result)
        syncInFlight = false
        if not equipped or not SameInstance(equipped.itemInstanceId, leaseItem)
            or equipped.generation ~= leaseGeneration then
            return
        end

        if result and result.ok then
            equipped.ammo = tonumber(result.value.total) or submitted
            equipped.loaded = tonumber(result.value.loaded) or submittedLoaded
            equipped.reserve = tonumber(result.value.reserve) or (equipped.ammo - equipped.loaded)
            equipped.condition = tonumber(result.value.condition) or equipped.condition
            if Config.DevMode then
                print(('[feather-weapons] checkpoint consumed=%s total=%s loaded=%s condition=%s'):format(
                    tostring(result.value.consumed), tostring(equipped.ammo),
                    tostring(equipped.loaded), tostring(equipped.condition)))
            end

            if result.value.broken then
                print('[feather-weapons] weapon condition is broken')
                ClearNativeWeapon()
                return
            end

            if desiredAmmo > equipped.ammo then
                desiredAmmo = equipped.ammo
            end
        else
            ResolveCheckpointWaiters(result or {
                ok = false,
                code = 'checkpoint_failed',
                message = 'Weapon state could not be saved.'
            })
            FeatherWeaponsClient.Reconcile()
            return
        end

        if desiredAmmo < equipped.ammo or desiredLoaded ~= equipped.loaded then
            FlushConsumption()
        else
            ResolveCheckpointWaiters({
                ok = true,
                value = {
                    total = equipped.ammo, loaded = equipped.loaded, reserve = equipped.reserve
                }
            })
        end

        if unloadQueued then
            unloadQueued = false
            BeginUnload()
        end
    end)
end

local function CaptureNativeState()
    if not equipped then return true end

    local ped = PlayerPedId()
    local observedTotal = math.max(0, math.floor(tonumber(
        GetPedAmmoByType(ped, joaat(equipped.nativeAmmoName))) or 0))
    local clipOk, clipAmount = GetAmmoInClip(ped, joaat(equipped.nativeWeaponName))
    if observedTotal > equipped.ammo then return false end

    desiredAmmo = observedTotal
    if clipOk == true or clipOk == 1 then
        desiredLoaded = math.max(0, math.min(observedTotal, math.floor(tonumber(clipAmount) or 0)))
    end

    return true
end

local function CapturePairNativeState()
    local primary = equipped
    local secondary = offhand
    if not primary or not secondary then return false end

    local ped = PlayerPedId()
    local primaryOk, primaryLoaded, offhandOk, offhandLoaded = PairNativeClips(primary, secondary)
    if not primaryOk or not offhandOk then return false end

    local total = math.max(0, math.floor(tonumber(
        GetPedAmmoByType(ped, joaat(primary.nativeAmmoName))) or 0))
    primaryLoaded = math.max(0, math.floor(tonumber(primaryLoaded) or 0))
    offhandLoaded = math.max(0, math.floor(tonumber(offhandLoaded) or 0))
    local observed = pairObserved or {
        primary = primaryLoaded,
        offhand = offhandLoaded,
        total = total
    }
    pairObserved = observed
    if primaryLoaded < observed.primary then
        pairConsumed.primary = pairConsumed.primary + (observed.primary - primaryLoaded)
    end

    if offhandLoaded < observed.offhand then
        pairConsumed.offhand = pairConsumed.offhand + (observed.offhand - offhandLoaded)
    end

    observed.primary = primaryLoaded
    observed.offhand = offhandLoaded
    observed.total = total
    return total <= (primary.ammo + secondary.ammo)
end

local function FlushPairConsumption()
    if pairSyncInFlight then return end

    if not CapturePairNativeState() then
        ResolveCheckpointWaiters({
            ok = false,
            code = 'invalid_native_state',
            message = 'Native pair ammunition state is invalid.'
        })
        return
    end

    local observed = pairObserved
    local primary = equipped
    local secondary = offhand
    if not observed or not primary or not secondary then
        ResolveCheckpointWaiters({
            ok = false,
            code = 'pair_state_changed',
            message = 'Weapon pair changed before its ammunition checkpoint.'
        })
        return
    end

    local submitted = {
        total = observed.total,
        primaryLoaded = observed.primary,
        offhandLoaded = observed.offhand,
        primaryConsumed = pairConsumed.primary,
        offhandConsumed = pairConsumed.offhand,
        primaryItem = primary.itemInstanceId,
        offhandItem = secondary.itemInstanceId,
        primaryGeneration = primary.generation,
        offhandGeneration = secondary.generation
    }
    if submitted.primaryConsumed == 0 and submitted.offhandConsumed == 0
        and submitted.primaryLoaded == primary.loaded
        and submitted.offhandLoaded == secondary.loaded
        and submitted.total == primary.ammo + secondary.ammo then
        ResolveCheckpointWaiters({
            ok = true,
            value = {
                total = submitted.total,
                slots = { primary = primary, offhand = secondary }
            }
        })
        return
    end

    pairSyncInFlight = true
    FeatherCore.RPC.Call('feather-weapons:ammo:pairSync', {
        total = submitted.total,
        slots = {
            primary = {
                itemInstanceId = submitted.primaryItem,
                generation = submitted.primaryGeneration,
                loaded = submitted.primaryLoaded,
                consumed = submitted.primaryConsumed
            },
            offhand = {
                itemInstanceId = submitted.offhandItem,
                generation = submitted.offhandGeneration,
                loaded = submitted.offhandLoaded,
                consumed = submitted.offhandConsumed
            }
        }
    }, function(result)
        pairSyncInFlight = false
        local currentPrimary = equipped
        local currentOffhand = offhand
        local currentObserved = pairObserved
        if not currentPrimary or not currentOffhand or not currentObserved
            or not SameInstance(currentPrimary.itemInstanceId, submitted.primaryItem)
            or not SameInstance(currentOffhand.itemInstanceId, submitted.offhandItem) then
            return
        end

        if not result or not result.ok then
            ResolveCheckpointWaiters(result or {
                ok = false,
                code = 'checkpoint_failed',
                message = 'Weapon pair state could not be saved.'
            })
            FeatherWeaponsClient.Reconcile()
            return
        end

        for slot, state in pairs({ primary = currentPrimary, offhand = currentOffhand }) do
            local value = result.value.slots[slot]
            state.ammo = tonumber(value.total) or state.ammo
            state.loaded = tonumber(value.loaded) or state.loaded
            state.reserve = tonumber(value.reserve) or state.reserve
            state.condition = tonumber(value.condition) or state.condition
            pairConsumed[slot] = math.max(0,
                pairConsumed[slot] - (slot == 'primary'
                    and submitted.primaryConsumed or submitted.offhandConsumed))
        end

        if pairConsumed.primary > 0 or pairConsumed.offhand > 0
            or currentObserved.primary ~= currentPrimary.loaded
            or currentObserved.offhand ~= currentOffhand.loaded
            or currentObserved.total ~= currentPrimary.ammo + currentOffhand.ammo then
            FlushPairConsumption()
        else
            ResolveCheckpointWaiters(result)
        end
    end)
end

function FeatherWeaponsClient.Checkpoint(callback)
    callback = type(callback) == 'function' and callback or function() end

    checkpointWaiters[#checkpointWaiters + 1] = callback
    if offhand then
        FlushPairConsumption()
        return
    end

    if not CaptureNativeState() then
        ResolveCheckpointWaiters({
            ok = false,
            code = 'invalid_native_state',
            message = 'Native ammunition exceeded the active weapon lease.'
        })
        return
    end

    FlushConsumption()
end

local function ScheduleRestoredWeaponsHolster()
    holsterSequence = holsterSequence + 1
    local sequence = holsterSequence
    local primaryItem = equipped and equipped.itemInstanceId or nil
    local primaryGeneration = equipped and equipped.generation or nil
    local offhandItem = offhand and offhand.itemInstanceId or nil
    local offhandGeneration = offhand and offhand.generation or nil

    for _, delay in ipairs({ 0, 250, 750, 1500 }) do
        SetTimeout(delay, function()
            if sequence ~= holsterSequence
                or not equipped
                or not SameInstance(equipped.itemInstanceId, primaryItem)
                or tonumber(equipped.generation) ~= tonumber(primaryGeneration)
                or (offhandItem ~= nil and (not offhand
                    or not SameInstance(offhand.itemInstanceId, offhandItem)
                    or tonumber(offhand.generation) ~= tonumber(offhandGeneration)))
                or (offhandItem == nil and offhand ~= nil) then
                return
            end
            -- Pair creation and native reload can select a hand after the
            -- reconcile callback returns. Reassert unarmed through that short
            -- settle window so character/resource restores finish holstered.
            local ped = PlayerPedId()
            HolsterPedWeapons(ped, true, true, true, true)
            SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true, 0, false, false)

            if Config.DevMode and delay == 1500 then
                print(('[feather-weapons] restored weapons holstered=%s'):format(
                    tostring(NativeTrue(Citizen.InvokeNative(0xBDD9C235D8D1052E, ped))))) -- IsPedCurrentWeaponHolstered
            end
        end)
    end
end

function FeatherWeaponsClient.Reconcile(callback, options)
    options = type(options) == 'table' and options or {}
    FeatherCore.RPC.Call('feather-weapons:state:get', {}, function(result, rpcError)
        if not result or not result.ok then
            if callback then
                callback(result, rpcError)
            end
            return
        end

        local slots = type(result.value.slots) == 'table' and result.value.slots or {}
        if slots.primary and slots.offhand then
            local applied, message = ApplyApprovedPair(slots.primary, slots.offhand)
            if not applied then Notify(message or 'Unable to restore the weapon pair.') end
        elseif result.value.equipped then
            ApplyApprovedWeapon(result.value.equipped)
        else
            ClearNativeWeapon()
        end

        if options.holster == true and (equipped or offhand) then
            ScheduleRestoredWeaponsHolster()
        end

        if callback then
            callback(result)
        end
    end)
end

local function RecoverLostOffhandEntitlement()
    if offhandRecoveryInFlight or not equipped or not offhand then return end
    offhandRecoveryInFlight = true
    FeatherWeaponsClient.Checkpoint(function(checkpoint)
        if Config.DevMode then
            print(('[feather-weapons] offhand entitlement lost nativeCheckpoint=%s recovery=authoritative')
                :format(checkpoint and checkpoint.ok and 'available' or 'unavailable'))
        end

        ClearNativeWeapon()
        FeatherWeaponsClient.Reconcile(function(result)
            offhandRecoveryInFlight = false
            if not result or not result.ok then
                Notify('Offhand entitlement was lost and the weapon pair could not be restored.')
            end
        end)
    end)
end

function FeatherWeaponsClient.Equip(itemInstanceId, callback, slot)
    slot = slot or 'primary'
    FeatherCore.RPC.Call('feather-weapons:equip:request', {
        itemInstanceId = itemInstanceId, slot = slot
    }, function(result, rpcError)
        if not result or not result.ok then
            if callback then callback(result, rpcError) end
            return
        end

        local authorization = result.value
        pendingToken, pendingNativeWeaponName = authorization.token, authorization.nativeWeaponName

        if authorization.slot == 'offhand' then
            FeatherCore.RPC.Call('feather-weapons:equip:acknowledge', {
                token = authorization.token
            }, function(ack, ackError)
                pendingToken, pendingNativeWeaponName = nil, nil
                if not ack or not ack.ok then
                    if callback then callback(ack, ackError) end
                    return
                end

                FeatherWeaponsClient.Reconcile(function(reconciled, reconcileError)
                    if callback then callback(reconciled, reconcileError) end
                end)
            end)
            return
        end

        local nativeHash = joaat(authorization.nativeWeaponName)
        ResetNativeAmmo('weapon-equipped', authorization.nativeAmmoName)
        GiveApprovedNativeWeapon(authorization.nativeWeaponName, authorization.nativeAmmoName, authorization.ammo,
            authorization.loaded, authorization.attachments)
        FeatherCore.RPC.Call('feather-weapons:equip:acknowledge', { token = authorization.token },
            function(ack, ackError)
                if not ack or not ack.ok then
                    RemoveNativeWeapon(PlayerPedId(), nativeHash)
                    ResetNativeAmmo('equip-rejected', authorization.nativeAmmoName)
                    pendingToken, pendingNativeWeaponName = nil, nil
                    if callback then
                        callback(ack, ackError)
                    end
                    return
                end

                ApplyApprovedWeapon(ack.value)
                pendingToken, pendingNativeWeaponName = nil, nil
                if callback then
                    callback(ack)
                end
            end)
    end)
end

function FeatherWeaponsClient.Unequip(callback, slot)
    slot = slot or 'primary'
    FeatherCore.RPC.Call('feather-weapons:equip:unequip', { slot = slot }, function(result, rpcError)
        if result and result.ok then
            ClearNativeWeapon()
            FeatherWeaponsClient.Reconcile()
        end

        if callback then
            callback(result, rpcError)
        end
    end)
end

-- Read-only state used by isolated development diagnostics. The probe must not
-- replace or mutate an Inventory-authorized weapon.
function FeatherWeaponsClient.GetDiagnosticState()
    if not equipped then
        return { equipped = false }
    end

    return {
        equipped = true,
        itemInstanceId = equipped.itemInstanceId,
        definitionId = equipped.definitionId,
        nativeWeaponName = equipped.nativeWeaponName,
        nativeAmmoName = equipped.nativeAmmoName,
        generation = equipped.generation,
        sessionId = equipped.sessionId,
        offhand = offhand and {
            itemInstanceId = offhand.itemInstanceId,
            definitionId = offhand.definitionId,
            nativeWeaponName = offhand.nativeWeaponName,
            generation = offhand.generation
        } or nil
    }
end

function FeatherWeaponsClient.Unload(amount, callback)
    FeatherCore.RPC.Call('feather-weapons:ammo:unload', { amount = amount }, function(result, rpcError)
        if result and result.ok and equipped then
            local slot = result.value.slot == 'offhand' and 'offhand' or 'primary'
            local state = slot == 'offhand' and offhand or equipped
            if state then
                state.ammo = tonumber(result.value.total) or 0
                state.loaded = tonumber(result.value.loaded) or 0
                state.reserve = tonumber(result.value.reserve) or 0
            end

            if offhand then
                -- Rebuild from authoritative slot metadata. A hash-addressed
                -- clip write cannot target one of two matching native weapons.
                ClearNativeWeapon()
                FeatherWeaponsClient.Reconcile()
            else
                desiredAmmo = equipped.ammo
                desiredLoaded = equipped.loaded
                RestoreApprovedNativeWeapon(equipped.nativeWeaponName,
                    result.value.nativeAmmoName or equipped.nativeAmmoName, equipped.ammo,
                    equipped.loaded, equipped.attachments)
            end
        end

        if callback then
            callback(result, rpcError)
        end
    end)
end

BeginUnload = function()
    if unloadInFlight then return end

    if not equipped then
        Notify('No weapon is equipped.')
        return
    end

    if syncInFlight or (desiredAmmo ~= nil and desiredAmmo < equipped.ammo) then
        unloadQueued = true
        FlushConsumption()
        return
    end

    local function unloadAfterCheckpoint()
        FeatherWeaponsClient.Unload(nil, function(result, rpcError)
            unloadInFlight = false
            if result and result.ok then
                Notify(('Unloaded %s round%s.'):format(
                    tostring(result.value.moved), result.value.moved == 1 and '' or 's'))
                return
            end

            local failure = result and result.error or rpcError
            Notify(failure and failure.message or 'Unable to unload.')
        end)
    end

    unloadInFlight = true
    if offhand then
        FeatherWeaponsClient.Checkpoint(function(checkpoint)
            if not checkpoint or checkpoint.ok ~= true then
                unloadInFlight = false
                local failure = checkpoint and (checkpoint.error or checkpoint)
                Notify(failure and failure.message
                    or 'Unable to checkpoint the weapon pair before unloading.')
                return
            end
            unloadAfterCheckpoint()
        end)
        return
    end
    unloadAfterCheckpoint()
end

function FeatherWeaponsClient.Repair(slot, callback)
    slot = slot or 'primary'
    local state = slot == 'offhand' and offhand or equipped
    if not state then
        if callback then callback({ ok = false, error = { message = 'No weapon is equipped in that slot.' } }) end
        return
    end

    FeatherCore.RPC.Call('feather-weapons:repair', {
        slot = slot,
        itemInstanceId = state.itemInstanceId,
        generation = state.generation
    }, function(result, rpcError)
        if result and result.ok and state and SameInstance(state.itemInstanceId, result.value.itemInstanceId) then
            state.condition = tonumber(result.value.condition) or state.condition
        end

        if callback then callback(result, rpcError) end
    end)
end

RegisterNetEvent('feather-weapons:client:useInventoryWeapon', function(itemInstanceId)
    if inventoryWeaponInFlight then return end

    if Config.DevMode then
        print(('[feather-weapons] inventory weapon requested item=%s'):format(tostring(itemInstanceId)))
    end

    inventoryWeaponInFlight = true
    if offhand and SameInstance(offhand.itemInstanceId, itemInstanceId) then
        FeatherWeaponsClient.Unequip(function(result, rpcError)
            inventoryWeaponInFlight = false
            if result and result.ok then
                Notify('Offhand weapon unequipped.')
                return
            end

            local failure = result and result.error or rpcError
            Notify(failure and failure.message or 'Unable to unequip this weapon.')
        end, 'offhand')
        return
    end
    if equipped and SameInstance(equipped.itemInstanceId, itemInstanceId) then
        local promoting = offhand ~= nil
        FeatherWeaponsClient.Unequip(function(result, rpcError)
            inventoryWeaponInFlight = false
            if result and result.ok then
                Notify(promoting and 'Primary removed; offhand promoted.' or 'Weapon unequipped.')
                return
            end

            local failure = result and result.error or rpcError
            Notify(failure and failure.message or 'Unable to unequip this weapon.')
        end, 'primary')
        return
    end

    local requestedSlot = equipped and 'offhand' or 'primary'
    FeatherWeaponsClient.Equip(itemInstanceId, function(result, rpcError)
        inventoryWeaponInFlight = false
        if result and result.ok then
            Notify(requestedSlot == 'offhand' and 'Offhand weapon equipped.' or 'Weapon equipped.')
            if Config.DevMode then
                print(('[feather-weapons] inventory equip succeeded item=%s'):format(tostring(itemInstanceId)))
            end
            return
        end

        local failure = result and result.error or rpcError
        Notify(failure and failure.message or 'Unable to equip this weapon.')
        if Config.DevMode then
            print(('[feather-weapons] inventory equip failed item=%s code=%s message=%s'):format(
                tostring(itemInstanceId), tostring(failure and failure.code), tostring(failure and failure.message)))
        end
    end, requestedSlot)
end)

local function HandleAttachmentResult(result)
    if result and result.ok then
        local slot = result.value.slot or 'primary'
        local state = slot == 'offhand' and offhand or equipped
        if not state or not SameInstance(state.itemInstanceId, result.value.itemInstanceId) then
            Notify('Weapon state changed; reconciling attachments.')
            FeatherWeaponsClient.Reconcile()
            return
        end

        state.attachments = result.value.attachments or {}
        local message = result.value.installed and 'Attachment installed.' or 'Attachment removed.'
        if offhand then
            ClearNativeWeapon()
            FeatherWeaponsClient.Reconcile(function(reconciled)
                Notify(reconciled and reconciled.ok and message
                    or 'Attachment changed, but the weapon pair could not be restored.')
            end)
        else
            RestoreApprovedNativeWeapon(state.nativeWeaponName, state.nativeAmmoName, state.ammo,
                state.loaded, state.attachments)
            Notify(message)
        end
        return
    end

    local failure = result and result.error
    Notify(failure and failure.message or 'Unable to modify this weapon.')
end

local function RequestAttachmentMutation(route, request)
    FeatherWeaponsClient.Checkpoint(function(checkpoint)
        if not checkpoint or not checkpoint.ok then
            local failure = checkpoint and checkpoint.error or nil
            Notify(failure and failure.message
                or 'Unable to checkpoint weapon ammunition before modification.')
            return
        end
        FeatherCore.RPC.Call(route, request, function(result, rpcError)
            HandleAttachmentResult(result or { ok = false, error = rpcError })
        end)
    end)
end

RegisterNetEvent('feather-weapons:client:attachmentResult', HandleAttachmentResult)

local ModificationMenu = FeatherMenu:RegisterMenu('feather-weapons:modifications', {
    top = '3%',
    left = '3%',
    ['720width'] = '360px',
    ['1080width'] = '420px',
    ['2kwidth'] = '500px',
    ['4kwidth'] = '650px',
    draggable = true,
    canclose = true
}, {})

local ModificationPages = {}

local Styles = {
    header = { ['color'] = '#999' },
    subheader = { ['font-size'] = '1.778vmin', ['color'] = '#CC9900' },
    text = {
        ['color'] = '#C0C0C0',
        ['font-size'] = '1.481vmin',
        ['font-variant'] = 'small-caps',
        ['line-height'] = '1.8',
        ['white-space'] = 'pre-line',
    },
    button = { ['color'] = '#E0E0E0' },
    success = { ['color'] = '#66CC66' },
    danger = { ['color'] = '#CC3333' },
}

local function ResetModificationPages()
    ModificationMenu:Close()
    for key, page in pairs(ModificationPages) do
        page:UnRegister()
        ModificationPages[key] = nil
    end
    ModificationMenu.activePage = nil
end

local function NearGunsmithStation()
    local settings = Config.Attachments or {}
    if settings.requireStation ~= true then return true end

    local position = GetEntityCoords(PlayerPedId(), false, true)
    local distance = tonumber(settings.interactionDistance) or 2.0
    for _, station in pairs(settings.stations or {}) do
        local coords = station.coords
        if coords then
            local dx, dy, dz = position.x - coords.x, position.y - coords.y, position.z - coords.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= distance then return true end
        end
    end
    return false
end

local BuildModificationPage

local function OpenModificationMenu()
    if not equipped then
        Notify('Equip a weapon before modifying it.')
        return
    end

    if not NearGunsmithStation() then
        Notify('Visit a gunsmith bench to modify this weapon.')
        return
    end

    ResetModificationPages()
    ModificationPages.primary = BuildModificationPage('primary')
    if offhand then ModificationPages.offhand = BuildModificationPage('offhand') end

    if offhand then
        local selector = ModificationMenu:RegisterPage('feather-weapons:select-weapon-slot')
        ModificationPages.selector = selector

        selector:RegisterElement('header', { value = 'Weapon Modifications', slot = 'header', style = Styles.header })

        selector:RegisterElement('subheader', { value = 'Choose a weapon', slot = 'header', style = Styles.subheader })

        for _, slot in ipairs({ 'primary', 'offhand' }) do
            local selected = slot == 'offhand' and offhand or equipped
            selector:RegisterElement('button', {
                label = ('%s: %s'):format(slot == 'primary' and 'Primary' or 'Offhand', selected.definitionId or 'Equipped weapon'),
                slot = 'content',
                style = Styles.button
            }, function()
                ModificationPages[slot]:RouteTo()
            end)
        end

        ModificationMenu:Open({ startupPage = selector })
        return
    end
    ModificationMenu:Open({ startupPage = ModificationPages.primary })
end

BuildModificationPage = function(slot)
    local selected = slot == 'offhand' and offhand or equipped
    if not selected then return nil end

    local page = ModificationMenu:RegisterPage(('feather-weapons:installed-attachments:%s'):format(slot))

    page:RegisterElement('header', { value = 'Weapon Modifications', slot = 'header', style = Styles.header })

    page:RegisterElement('subheader', {
        value = ('%s: %s'):format(slot == 'primary' and 'Primary' or 'Offhand', selected.definitionId or 'Equipped weapon'),
        slot = 'header',
        style = Styles.subheader
    })

    page:RegisterElement('line', { slot = 'header' })

    local installedIds = {}
    for _, installed in ipairs(selected.attachments or {}) do
        installedIds[installed.definitionId] = true
    end

    local weaponDefinition = WeaponDefinitionCatalog.weapons[selected.definitionId]
    local compatibleIds = {}
    for _, attachmentIds in pairs(weaponDefinition and weaponDefinition.attachmentSlots or {}) do
        for _, attachmentId in ipairs(attachmentIds) do compatibleIds[attachmentId] = true end
    end

    for attachmentId in pairs(compatibleIds) do
        if not installedIds[attachmentId] then
            local definition = WeaponDefinitionCatalog.attachments[attachmentId]
            page:RegisterElement('button', {
                label = ('Install %s'):format(definition and definition.label or attachmentId:gsub('_', ' ')),
                slot = 'content',
                style = Styles.button
            }, function()
                ModificationMenu:Close()
                RequestAttachmentMutation('feather-weapons:attachment:install', {
                    attachmentId = attachmentId,
                    slot = slot,
                    itemInstanceId = selected.itemInstanceId,
                    generation = selected.generation
                })
            end)
        end
    end

    if not selected.attachments or #selected.attachments == 0 then
        page:RegisterElement('textdisplay', { value = 'No attachments are installed.', slot = 'content' })
    else
        for _, installed in ipairs(selected.attachments) do
            local attachmentId = installed.definitionId
            page:RegisterElement('button', {
                label = ('Remove %s'):format(attachmentId:gsub('_', ' ')),
                slot = 'content',
                style = Styles.button
            }, function()
                ModificationMenu:Close()
                RequestAttachmentMutation('feather-weapons:attachment:remove', {
                    attachmentId = attachmentId,
                    slot = slot,
                    itemInstanceId = selected.itemInstanceId,
                    generation = selected.generation
                })
            end)
        end
    end
    return page
end

local function HandleRepairResult(result)
    if result and result.ok then
        local slot = result.value.slot or 'primary'
        local state = slot == 'offhand' and offhand or equipped
        if state and SameInstance(state.itemInstanceId, result.value.itemInstanceId) then
            state.condition = tonumber(result.value.condition) or state.condition
        end

        Notify(('Weapon repaired by %s%%.'):format(tostring(result.value.restored)))
        return
    end

    local failure = result and result.error
    Notify(failure and failure.message or 'Unable to repair this weapon.')
end

RegisterNetEvent('feather-weapons:client:inventoryRepairResult', HandleRepairResult)

local RepairMenu = FeatherMenu:RegisterMenu('feather-weapons:repair-selection', {
    top = '3%',
    left = '3%',
    ['720width'] = '360px',
    ['1080width'] = '420px',
    ['2kwidth'] = '500px',
    ['4kwidth'] = '650px',
    draggable = true,
    canclose = true
}, {})
local RepairPage = nil

RegisterNetEvent('feather-weapons:client:repairSlotRequested', function()
    if not equipped or not offhand then
        Notify('The equipped weapon pair changed before repair selection.')
        return
    end

    if RepairPage then
        RepairMenu:Close()
        RepairPage:UnRegister()
        RepairPage = nil
        RepairMenu.activePage = nil
    end

    RepairPage = RepairMenu:RegisterPage('feather-weapons:repair-slot')

    RepairPage:RegisterElement('header', { value = 'Repair Weapon', slot = 'header', style = Styles.header })

    RepairPage:RegisterElement('subheader', { value = 'Choose a weapon', slot = 'header', style = Styles.subheader })

    for _, slot in ipairs({ 'primary', 'offhand' }) do
        local state = slot == 'offhand' and offhand or equipped
        RepairPage:RegisterElement('button', {
            label = ('%s: %s (%s%%)'):format(slot == 'primary' and 'Primary' or 'Offhand',
                state.definitionId or 'Equipped weapon', tostring(state.condition)),
            slot = 'content',
            style = Styles.button
        }, function()
            RepairMenu:Close()
            FeatherCore.RPC.Call('feather-weapons:repair:select', { slot = slot }, function(result, rpcError)
                HandleRepairResult(result or { ok = false, error = rpcError })
            end)
        end)
    end

    RepairMenu:Open({ startupPage = RepairPage })
end)

RegisterNetEvent('feather-weapons:client:clearAuthorization', function(token)
    if pendingToken == token then
        ClearNativeWeapon()
    end
end)

RegisterNetEvent('feather-weapons:client:inventoryAmmoResult', function(result)
    if result and result.ok and equipped then
        local slot = result.value.slot == 'offhand' and 'offhand' or 'primary'
        local state = slot == 'offhand' and offhand or equipped
        if not state then
            Notify('The selected weapon slot is no longer equipped.')
            return
        end

        state.ammo = tonumber(result.value.total) or state.ammo
        state.loaded = tonumber(result.value.loaded) or state.loaded
        state.reserve = tonumber(result.value.reserve) or (state.ammo - state.loaded)
        if offhand then
            local pairTotal = equipped.ammo + offhand.ammo
            SetPedAmmoByType(PlayerPedId(), joaat(equipped.nativeAmmoName), pairTotal)
            pairObserved = pairObserved or {}
            pairObserved.total = pairTotal
        else
            desiredAmmo, desiredLoaded = equipped.ammo, equipped.loaded
            SetNativeAmmo(result.value.nativeAmmoName or equipped.nativeAmmoName,
                equipped.ammo, equipped.nativeWeaponName, equipped.loaded)
        end

        Notify(('Escrowed %s cartridge%s.'):format(
            tostring(result.value.moved), result.value.moved == 1 and '' or 's'))
        return
    end

    local failure = result and result.error
    Notify(failure and failure.message or 'Unable to escrow ammunition.')
end)

RegisterNetEvent('feather-weapons:client:clear', ClearNativeWeapon)

RegisterNetEvent('feather-weapons:client:reconcile', function()
    FeatherWeaponsClient.Reconcile()
end)

RegisterNetEvent('feather-weapons:client:forceReconcile', function()
    ClearNativeWeapon()
    FeatherWeaponsClient.Reconcile()
end)

if Config.Controls and Config.Controls.unload and Config.Controls.unload.enabled then
    local unloadControl = Config.Controls.unload
    RegisterCommand(unloadControl.command, BeginUnload, false)
    RegisterKeyMapping(unloadControl.command, 'Unload equipped weapon', 'keyboard', unloadControl.defaultKey or 'U')
end

if Config.Controls and Config.Controls.modify and Config.Controls.modify.enabled then
    local modifyControl = Config.Controls.modify
    RegisterCommand(modifyControl.command, OpenModificationMenu, false)
    RegisterKeyMapping(modifyControl.command, 'Modify equipped weapon', 'keyboard', modifyControl.defaultKey or 'F6')
end

CreateThread(function()
    local runtimeConfig = Config.Runtime or {}
    local observationInterval = math.max(25, math.floor(tonumber(runtimeConfig.observationIntervalMs) or 50))
    local checkpointDebounce = math.max(0, math.floor(tonumber(runtimeConfig.checkpointDebounceMs) or 250))
    local wasDead = false

    while true do
        if equipped and not offhand and desiredAmmo ~= nil then
            local itemInstanceId = equipped.itemInstanceId
            local generation = equipped.generation
            local ammoHash = equipped.nativeAmmoName and joaat(equipped.nativeAmmoName) or nil
            if ammoHash then
                local clipOk, clipAmount = GetAmmoInClip(PlayerPedId(), joaat(equipped.nativeWeaponName))
                local clipChanged = false
                if clipOk == true or clipOk == 1 then
                    local observedLoaded = math.max(0, math.floor(tonumber(clipAmount) or 0))
                    clipChanged = desiredLoaded ~= nil and observedLoaded ~= desiredLoaded
                    desiredLoaded = observedLoaded
                end

                local observed = math.max(0, math.floor(tonumber(GetPedAmmoByType(PlayerPedId(), ammoHash)) or 0))
                if observed < desiredAmmo then
                    desiredAmmo = observed
                    SetTimeout(checkpointDebounce, function()
                        if equipped and SameInstance(equipped.itemInstanceId, itemInstanceId)
                            and equipped.generation == generation then
                            FlushConsumption()
                        end
                    end)
                elseif clipChanged then
                    SetTimeout(checkpointDebounce, function()
                        if equipped and SameInstance(equipped.itemInstanceId, itemInstanceId)
                            and equipped.generation == generation then
                            FlushConsumption()
                        end
                    end)
                elseif observed > equipped.ammo and not observerCorrectionPending then
                    observerCorrectionPending = true
                    if Config.DevMode then
                        print(('[feather-weapons] native ammo exceeded lease observed=%d approved=%d generation=%s')
                            :format(observed, equipped.ammo, tostring(generation)))
                    end
                    FeatherWeaponsClient.Reconcile()
                elseif observed <= equipped.ammo then
                    observerCorrectionPending = false
                end
            end

            local deadState = IsEntityDead(PlayerPedId())
            local dead = deadState == true or deadState == 1
            if dead and not wasDead then
                -- Death is a persistence boundary. Capture and submit immediately;
                -- ordinary firing/reload observations remain debounced.
                CaptureNativeState()
                FlushConsumption()
            end

            wasDead = dead
            Wait(observationInterval)
        else
            wasDead = false
            Wait(500)
        end
    end
end)

CreateThread(function()
    local runtimeConfig = Config.Runtime or {}
    local observationInterval = math.max(25, math.floor(tonumber(runtimeConfig.observationIntervalMs) or 50))
    local checkpointDebounce = math.max(0, math.floor(tonumber(runtimeConfig.checkpointDebounceMs) or 250))

    while true do
        if equipped and offhand and pairObserved then
            local ped = PlayerPedId()
            if not NativeTrue(GetAllowDualWield(ped)) then
                RecoverLostOffhandEntitlement()
                Wait(500)
            else
                local primaryOk, primaryLoaded, offhandOk, offhandLoaded = PairNativeClips(equipped, offhand)
                if primaryOk and offhandOk then
                    primaryLoaded = math.max(0, math.floor(tonumber(primaryLoaded) or 0))
                    offhandLoaded = math.max(0, math.floor(tonumber(offhandLoaded) or 0))
                    local total = math.max(0, math.floor(tonumber(GetPedAmmoByType(ped, joaat(equipped.nativeAmmoName))) or 0))
                    if primaryLoaded < pairObserved.primary then
                        pairConsumed.primary = pairConsumed.primary + (pairObserved.primary - primaryLoaded)
                    end

                    if offhandLoaded < pairObserved.offhand then
                        pairConsumed.offhand = pairConsumed.offhand + (pairObserved.offhand - offhandLoaded)
                    end

                    local changed = primaryLoaded ~= pairObserved.primary
                        or offhandLoaded ~= pairObserved.offhand or total ~= pairObserved.total
                    pairObserved.primary, pairObserved.offhand, pairObserved.total = primaryLoaded, offhandLoaded, total
                    if changed and not pairCheckpointPending then
                        pairCheckpointPending = true
                        SetTimeout(checkpointDebounce, function()
                            pairCheckpointPending = false
                            if equipped and offhand then
                                FlushPairConsumption()
                            end
                        end)
                    end
                end
                Wait(observationInterval)
            end
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if equipped and equipped.attachments and #equipped.attachments > 0
            and GetGameTimer() < attachmentReconcileUntil then
            ApplyNativeAttachments(equipped.nativeWeaponName, equipped.attachments)
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('Feather:Character:Spawned', function()
    RegisterCharacterLogoutCheckpoint()
    FeatherWeaponsClient.Reconcile(nil, { holster = true })
end)

AddEventHandler('Feather:Character:Logout', function()
    inventoryWeaponInFlight = false
    ClearNativeWeapon()
end)

RegisterCharacterLogoutCheckpoint = function()
    if GetResourceState('feather-character') ~= 'started' then return end

    local called, result = pcall(function()
        return exports['feather-character']:RegisterLogoutCheckpoint('feather-weapons:runtime', 'CheckpointBeforeLogout')
    end)

    if Config.DevMode then
        local passed = called and result and result.ok == true
        local failure = type(result) == 'table' and (result.error or result) or nil
        print(('[feather-weapons] character logout checkpoint registration %s code=%s message=%s'):format(
            passed and 'PASS' or 'FAIL',
            tostring(passed and 'none' or (failure and failure.code) or 'export_error'),
            tostring(passed and 'none' or (failure and failure.message) or result)))
    end
end

exports('CheckpointBeforeLogout', function()
    local pending = promise.new()
    FeatherWeaponsClient.Checkpoint(function(checkpoint)
        pending:resolve(checkpoint)
    end)

    local checkpoint = Citizen.Await(pending)
    if Config.DevMode then
        print(('[feather-weapons] logout checkpoint %s total=%s loaded=%s'):format(
            checkpoint and checkpoint.ok and 'PASS' or 'FAIL',
            tostring(checkpoint and checkpoint.value and checkpoint.value.total),
            tostring(checkpoint and checkpoint.value and checkpoint.value.loaded)))
    end
    return checkpoint
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RegisterCharacterLogoutCheckpoint()
        FeatherWeaponsClient.Reconcile(nil, { holster = true })
    elseif resourceName == 'feather-character' then
        RegisterCharacterLogoutCheckpoint()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ClearNativeWeapon()
    end
end)

if Config.DevMode then
    print(('[feather-weapons] client contract=%d dualSlots=true primaryPromotion=true'):format(clientContract))

    RegisterCommand('weaponstate', function()
        FeatherWeaponsClient.Reconcile(function(result, rpcError)
            if result and result.ok then
                local state = result.value.equipped
                print(('[feather-weapons] state equipped=%s item=%s generation=%s total=%s loaded=%s reserve=%s condition=%s')
                    :format(
                        tostring(state ~= nil), tostring(state and state.itemInstanceId),
                        tostring(state and state.generation),
                        tostring(state and state.ammo), tostring(state and state.loaded),
                        tostring(state and state.reserve), tostring(state and state.condition)))
                if state then
                    local attachmentIds = {}
                    for _, attachment in ipairs(state.attachments or {}) do
                        attachmentIds[#attachmentIds + 1] = tostring(attachment.definitionId)
                    end

                    print(('[feather-weapons] attachments count=%s ids=%s'):format(
                        tostring(#attachmentIds), #attachmentIds > 0 and table.concat(attachmentIds, ',') or 'none'))

                    local ped = PlayerPedId()
                    local clipOk, nativeLoaded = GetAmmoInClip(ped, joaat(state.nativeWeaponName))
                    local nativeTotal = GetPedAmmoByType(ped, joaat(state.nativeAmmoName))
                    print(('[feather-weapons] native total=%s loaded=%s clipOk=%s'):format(
                        tostring(nativeTotal), tostring(nativeLoaded), tostring(clipOk)))
                end

                local secondary = result.value.slots and result.value.slots.offhand or nil
                if secondary then
                    local clipOk, nativeLoaded = GetAmmoInClip(PlayerPedId(), joaat(secondary.nativeWeaponName))
                    print(('[feather-weapons] offhand item=%s generation=%s total=%s loaded=%s reserve=%s condition=%s attachments=%s nativeLoaded=%s clipOk=%s'):format(
                        tostring(secondary.itemInstanceId), tostring(secondary.generation),
                        tostring(secondary.ammo), tostring(secondary.loaded),
                        tostring(secondary.reserve), tostring(secondary.condition),
                        tostring(#(secondary.attachments or {})),
                        tostring(nativeLoaded), tostring(clipOk)
                    ))

                    print(('[feather-weapons] pair nativeTotal=%s consumed=%s/%s'):format(
                        tostring(GetPedAmmoByType(PlayerPedId(), joaat(secondary.nativeAmmoName))),
                        tostring(pairConsumed.primary), tostring(pairConsumed.offhand)
                    ))
                end
                return
            end

            local failure = result and result.error or rpcError
            print(('[feather-weapons] state failed: %s'):format(failure and (tostring(failure.code) .. ' - ' .. tostring(failure.message)) or 'no response'))
        end)
    end, false)

    RegisterCommand('WeaponDualEntitlementRemove', function()
        if not offhand then
            print('[feather-weapons] offhand entitlement remove skipped: no offhand equipped')
            return
        end

        RemoveOffhandEntitlements()
        SetAllowDualWield(PlayerPedId(), false)
        print('[feather-weapons] offhand entitlement removed; awaiting fail-closed recovery')
    end, false)
end

exports('initiate', function() return FeatherWeaponsClient end)

FeatherWeaponsClientReady = true
