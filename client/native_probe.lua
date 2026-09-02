local settings = Config.NativeProbe or {}
if Config.DevMode ~= true or settings.enabled ~= true then return end

local weaponName = settings.weapon or 'WEAPON_REVOLVER_CATTLEMAN'
local configuredOffhandWeaponName = settings.offhandWeapon or 'WEAPON_REVOLVER_SCHOFIELD'
local offhandWeaponName = configuredOffhandWeaponName
local ammoName = settings.ammo or 'AMMO_REVOLVER'
local weaponHash = joaat(weaponName)
local offhandWeaponHash = joaat(offhandWeaponName)
local ammoHash = joaat(ammoName)
local capacity = math.max(1, math.floor(tonumber(settings.capacity) or 6))
local primaryAttachPoint = math.floor(tonumber(settings.primaryAttachPoint) or 2)
local offhandAttachPoint = math.floor(tonumber(settings.offhandAttachPoint) or 3)
local interval = math.max(25, math.floor(tonumber(settings.observationIntervalMs) or 50))
local active = false
local watching = false
local previous = nil
local marks = {}
local markCounter = 0
local logicalItem = 'unlabeled'
local addReason = joaat('ADD_REASON_DEFAULT')
local nativeRemoveReason = joaat('REMOVE_REASON_CLIENT_PURGED')
local offhandUnlock = -200143754
local dualOverride = nil
local dualEntitlements = {}
local dualWeaponCopies = {}

local function NativeBuffer(length)
    return string.rep('\0', math.max(41, length))
end

local function NativeTrue(value)
    return value == true or value == 1
end

local function GetDualWieldAllowed(ped)
    return NativeTrue(GetAllowDualWield(ped))
end

local function SetDualWieldAllowed(ped, allowed)
    SetAllowDualWield(ped, allowed == true)
end

local function IsOffhandUnlocked()
    return NativeTrue(Citizen.InvokeNative(0xC4B660C7B6040E75, offhandUnlock))
end

local function IsOffhandVisible()
    return NativeTrue(Citizen.InvokeNative(0x8588A14B75AF096B, offhandUnlock))
end

local function SetOffhandUnlocked(unlocked)
    Citizen.InvokeNative(0x1B7C5ADA8A6910A0, offhandUnlock, unlocked == true)
end

local function SetOffhandVisible(visible)
    Citizen.InvokeNative(0x46B901A8ECDB5A61, offhandUnlock, visible == true)
end

local function InventoryGuid(inventoryId, parentGuid, category, slotId)
    local guid = NativeBuffer(8 * 13)
    local resolved = Citizen.InvokeNative(0x886DFD3E185C8A89,
        inventoryId, parentGuid, category, slotId, guid)
    return NativeTrue(resolved) and guid or nil
end

local function AddNativeWardrobeEntitlement(itemName, slotId)
    local inventoryId = 1
    local itemHash = joaat(itemName)
    local existing = math.max(0, math.floor(tonumber(Citizen.InvokeNative(
        0xE787F05DFC977BDE, inventoryId, itemHash, false)) or 0))
    if existing > 0 then
        return { ok = true, itemName = itemName, existing = true, count = existing }
    end
    if not NativeTrue(Citizen.InvokeNative(0x6D5D51B188333FD1, itemHash, 0)) then
        return { ok = false, itemName = itemName, stage = 'item-invalid' }
    end

    local characterGuid = InventoryGuid(inventoryId, nil, joaat('CHARACTER'), 0xA1212100)
    if not characterGuid then
        return { ok = false, itemName = itemName, stage = 'character-guid' }
    end
    local wardrobeGuid = InventoryGuid(inventoryId, characterGuid, joaat('WARDROBE'), 0x3DABBFA7)
    if not wardrobeGuid then
        return { ok = false, itemName = itemName, stage = 'wardrobe-guid' }
    end

    local itemGuid = NativeBuffer(8 * 13)
    local added = Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemGuid,
        wardrobeGuid, itemHash, slotId, 1, addReason)
    if not NativeTrue(added) then
        return { ok = false, itemName = itemName, stage = 'add' }
    end
    local equipped = Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemGuid, true)
    if not NativeTrue(equipped) then
        Citizen.InvokeNative(0x3E4E811480B3AE79, inventoryId, itemGuid, 1,
            joaat('REMOVE_REASON_DEFAULT'))
        return { ok = false, itemName = itemName, stage = 'equip' }
    end

    dualEntitlements[#dualEntitlements + 1] = {
        inventoryId = inventoryId,
        itemName = itemName,
        guid = itemGuid
    }
    return { ok = true, itemName = itemName, existing = false, count = 1 }
end

local function RemoveProbeEntitlements()
    for index = #dualEntitlements, 1, -1 do
        local entitlement = dualEntitlements[index]
        local removed = Citizen.InvokeNative(0x3E4E811480B3AE79,
            entitlement.inventoryId, entitlement.guid, 1, joaat('REMOVE_REASON_DEFAULT'))
        print(('[WeaponNativeProbe] dual-entitlement remove item=%s removed=%s'):format(
            entitlement.itemName, tostring(NativeTrue(removed))))
    end
    dualEntitlements = {}
end

local function RemoveProbeWeaponCopies()
    for index = #dualWeaponCopies, 1, -1 do
        local copy = dualWeaponCopies[index]
        local removed = Citizen.InvokeNative(0x3E4E811480B3AE79,
            copy.inventoryId, copy.guid, 1, joaat('REMOVE_REASON_DEFAULT'))
        print(('[WeaponNativeProbe] dual-copy remove slot=%d weapon=%s removed=%s'):format(
            copy.slot, copy.weaponName, tostring(NativeTrue(removed))))
    end
    dualWeaponCopies = {}
end

local function AddNativeWeaponCopy(ped, weapon, slot)
    local inventoryId = 1
    local itemHash = joaat(weapon)
    if not NativeTrue(Citizen.InvokeNative(0x6D5D51B188333FD1, itemHash, 0)) then
        return false, 'item-invalid'
    end

    local characterGuid = InventoryGuid(inventoryId, nil, joaat('CHARACTER'), 0xA1212100)
    if not characterGuid then return false, 'character-guid' end
    local carriedGuid = InventoryGuid(inventoryId, characterGuid,
        joaat('CARRIED_WEAPONS'), joaat('SLOTID_CARRIED_WEAPONS'))
    if not carriedGuid then return false, 'carried-weapons-guid' end

    local itemGuid = NativeBuffer(8 * 13)
    local slotHash = joaat(('SLOTID_WEAPON_%d'):format(slot))
    local added = Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemGuid,
        carriedGuid, itemHash, slotHash, 1, addReason)
    if not NativeTrue(added) then return false, 'add' end

    local equipped = Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemGuid, true)
    if not NativeTrue(equipped) then
        Citizen.InvokeNative(0x3E4E811480B3AE79, inventoryId, itemGuid, 1,
            joaat('REMOVE_REASON_DEFAULT'))
        return false, 'equip'
    end

    Citizen.InvokeNative(0x12FB95FE3D579238, ped, itemGuid, true, slot, false, false)
    dualWeaponCopies[#dualWeaponCopies + 1] = {
        inventoryId = inventoryId,
        guid = itemGuid,
        slot = slot,
        weaponName = weapon
    }
    return true, 'ready'
end

local function MoveNativeWeaponCopy(copy, parentGuid, slot)
    local movedGuid = NativeBuffer(8 * 13)
    local moved = Citizen.InvokeNative(0xDCCAA7C3BFD88862,
        copy.inventoryId, copy.guid, parentGuid,
        joaat(('SLOTID_WEAPON_%d'):format(slot)), 1, movedGuid)
    if not NativeTrue(moved) then return false, 'move' end
    copy.guid = movedGuid
    copy.slot = slot
    return true, 'ready'
end

local function AddIdenticalWeaponPair(ped, weapon)
    local firstOk, firstStage = AddNativeWeaponCopy(ped, weapon, 0)
    if not firstOk then return false, false, firstStage, 'not-attempted' end

    local inventoryId = 1
    local characterGuid = InventoryGuid(inventoryId, nil, joaat('CHARACTER'), 0xA1212100)
    if not characterGuid then return true, false, 'ready', 'character-guid' end
    local carriedGuid = InventoryGuid(inventoryId, characterGuid,
        joaat('CARRIED_WEAPONS'), joaat('SLOTID_CARRIED_WEAPONS'))
    if not carriedGuid then return true, false, 'ready', 'carried-weapons-guid' end

    local firstCopy = dualWeaponCopies[#dualWeaponCopies]
    local moved, moveStage = MoveNativeWeaponCopy(firstCopy, carriedGuid, 1)
    if not moved then return true, false, 'ready', moveStage end

    -- RedM's native inventory expects the newly added weapon in slot 0. The
    -- existing GUID must be moved to slot 1 before the second copy is added.
    local secondOk, secondStage = AddNativeWeaponCopy(ped, weapon, 0)
    if not secondOk then return true, false, 'ready', secondStage end
    Citizen.InvokeNative(0x12FB95FE3D579238,
        ped, firstCopy.guid, true, 1, false, false)
    return true, true, 'ready', 'ready'
end

local function InventoryWeaponActive()
    local state = FeatherWeaponsClient and FeatherWeaponsClient.GetDiagnosticState
        and FeatherWeaponsClient.GetDiagnosticState() or nil
    return state and state.equipped == true, state
end

local function Clip(ped)
    local ok, amount = GetAmmoInClip(ped, weaponHash)
    return NativeTrue(ok), math.max(0, math.floor(tonumber(amount) or 0))
end

local function CurrentWeapon(ped)
    local ok, hash = GetCurrentPedWeapon(ped, true, 0, false)
    return NativeTrue(ok) and hash or 0
end

local function CurrentWeaponAt(ped, p2, attachPoint, p4)
    local ok, hash = GetCurrentPedWeapon(ped, p2, attachPoint, p4)
    return NativeTrue(ok), hash or 0
end

local function Snapshot()
    local ped = PlayerPedId()
    local clipOk, loaded = Clip(ped)
    local carried = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped)
    return {
        time = GetGameTimer(),
        ped = ped,
        selected = CurrentWeapon(ped),
        weapon = weaponHash,
        clipOk = clipOk,
        loaded = loaded,
        weaponTotal = math.max(0, math.floor(tonumber(GetAmmoInPedWeapon(ped, weaponHash)) or 0)),
        ammoTypeTotal = math.max(0, math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0)),
        reloading = NativeTrue(IsPedReloading(ped)),
        shooting = NativeTrue(IsPedShooting(ped)),
        dead = NativeTrue(IsEntityDead(ped)),
        mounted = NativeTrue(IsPedOnMount(ped)),
        walking = NativeTrue(IsPedWalking(ped)),
        running = NativeTrue(IsPedRunning(ped)),
        sprinting = NativeTrue(IsPedSprinting(ped)),
        inCover = NativeTrue(IsPedInCover(ped, true, true)),
        firstPersonAim = NativeTrue(IsFirstPersonAimCamActive()),
        carrying = carried ~= nil and carried ~= false and carried ~= 0,
        logicalItem = logicalItem
    }
end

local function Same(left, right)
    if not left or not right then return false end
    for _, key in ipairs({ 'selected', 'clipOk', 'loaded', 'weaponTotal', 'ammoTypeTotal',
        'reloading', 'shooting', 'dead', 'mounted', 'walking', 'running', 'sprinting',
        'inCover', 'firstPersonAim', 'carrying' }) do
        if left[key] ~= right[key] then return false end
    end
    return true
end

local function PrintSnapshot(label, snapshot)
    print(('[WeaponNativeProbe] %s item=%s selected=%s expected=%s clipOk=%s loaded=%d weaponTotal=%d '
        .. 'ammoTypeTotal=%d reloading=%s shooting=%s dead=%s mounted=%s walking=%s running=%s '
        .. 'sprinting=%s cover=%s firstPersonAim=%s carrying=%s'):format(
        tostring(label), tostring(snapshot.logicalItem), tostring(snapshot.selected), tostring(snapshot.weapon),
        tostring(snapshot.clipOk), snapshot.loaded, snapshot.weaponTotal, snapshot.ammoTypeTotal,
        tostring(snapshot.reloading),
        tostring(snapshot.shooting), tostring(snapshot.dead), tostring(snapshot.mounted),
        tostring(snapshot.walking), tostring(snapshot.running), tostring(snapshot.sprinting),
        tostring(snapshot.inCover), tostring(snapshot.firstPersonAim),
        tostring(snapshot.carrying)))
end

local function RefuseInventoryWeapon()
    local isActive, state = InventoryWeaponActive()
    if not isActive then return false end
    print(('[WeaponNativeProbe] REFUSED -- unequip Inventory weapon item=%s definition=%s first'):format(
        tostring(state.itemInstanceId), tostring(state.definitionId)))
    return true
end

local function RestoreDualWieldState()
    if not dualOverride then return end
    local ped = PlayerPedId()
    SetDualWieldAllowed(ped, dualOverride.allowed)
    SetOffhandUnlocked(dualOverride.unlocked)
    SetOffhandVisible(dualOverride.visible)
    print(('[WeaponNativeProbe] dual-allow restored allowed=%s unlocked=%s visible=%s'):format(
        tostring(GetDualWieldAllowed(ped)),
        tostring(IsOffhandUnlocked()),
        tostring(IsOffhandVisible())))
    dualOverride = nil
end

local function ClearNativeTestState(ped)
    -- SetPedAmmoByType(..., 0) did not lower an existing pool on the tested
    -- runtime. Remove the observed amount while its weapon is still present;
    -- removing the weapon first left the prior ceiling behind.
    local amount = math.max(0, math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0))
    if amount > 0 then
        Citizen.InvokeNative(0xB6CFEC32E3742779, ped, ammoHash, amount, 0xA07362E6)
        -- _REMOVE_AMMO_FROM_PED_BY_TYPE, REMOVE_REASON_DEBUG
    end
    local afterTypeRemoval = math.max(0,
        math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0))
    RemoveProbeWeaponCopies()
    RemoveWeaponFromPed(ped, weaponHash, true, nativeRemoveReason)
    if offhandWeaponHash ~= weaponHash then
        RemoveWeaponFromPed(ped, offhandWeaponHash, true, nativeRemoveReason)
    end
    local afterWeaponRemoval = math.max(0,
        math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0))
    print(('[WeaponNativeProbe] cleanup requested=%d afterType=%d afterWeapon=%d'):format(
        amount, afterTypeRemoval, afterWeaponRemoval))
end

local function GiveProbeWeapon(ped, hash, attachPoint, allowMultipleCopies, forceInHand, forceInHolster)
    GiveWeaponToPed(
        ped,
        hash,
        0,
        forceInHand == true,
        forceInHolster == true,
        attachPoint,
        allowMultipleCopies == true,
        0.5,
        1.0,
        addReason,
        true,
        0.0,
        false
    )
end

RegisterCommand('WeaponNativeProbePrepare', function(_, args)
    if RefuseInventoryWeapon() then return end
    local loaded = math.floor(tonumber(args and args[1]) or capacity)
    local total = math.floor(tonumber(args and args[2]) or loaded)
    logicalItem = tostring(args and args[3] or 'unlabeled')
    loaded = math.max(0, math.min(capacity, loaded))
    total = math.max(loaded, total)

    local ped = PlayerPedId()
    ClearNativeTestState(ped)
    GiveProbeWeapon(ped, weaponHash, 0, false, false, true)
    local clipSet = SetAmmoInClip(ped, weaponHash, loaded)
    SetPedAmmoByType(ped, ammoHash, total)
    SetCurrentPedWeapon(ped, weaponHash, true, 0, false, false)

    active = true
    previous = Snapshot()
    print(('[WeaponNativeProbe] prepare requestedLoaded=%d requestedTotal=%d clipSet=%s'):format(
        loaded, total, tostring(clipSet)))
    PrintSnapshot('prepared', previous)
    local setupPassed = previous.selected == weaponHash and previous.clipOk
        and previous.loaded == loaded and previous.weaponTotal == total
        and previous.ammoTypeTotal == total
    print(('[WeaponNativeProbe] setup %s'):format(setupPassed and 'PASS' or 'FAIL'))
end, false)

RegisterCommand('WeaponNativeProbeDualPrepare', function(_, args)
    if RefuseInventoryWeapon() then return end
    local primaryLoaded = math.max(0, math.min(capacity,
        math.floor(tonumber(args and args[1]) or capacity)))
    local offhandLoaded = math.max(0, math.min(capacity,
        math.floor(tonumber(args and args[2]) or capacity)))
    local total = math.max(primaryLoaded + offhandLoaded,
        math.floor(tonumber(args and args[3]) or (primaryLoaded + offhandLoaded)))
    local ped = PlayerPedId()

    ClearNativeTestState(ped)
    offhandWeaponName = tostring(args and args[4] or configuredOffhandWeaponName)
    offhandWeaponHash = joaat(offhandWeaponName)
    local primaryGranted, offhandGranted = true, true
    local primaryStage, offhandStage = 'hash-grant', 'hash-grant'
    if offhandWeaponHash == weaponHash then
        primaryGranted, offhandGranted, primaryStage, offhandStage =
            AddIdenticalWeaponPair(ped, weaponName)
    else
        GiveProbeWeapon(ped, weaponHash, primaryAttachPoint, false, true, false)
        GiveProbeWeapon(ped, offhandWeaponHash, offhandAttachPoint, false, true, false)
    end
    -- The offhand weapon entity is not queryable immediately after its grant.
    -- This probe-only settle point tests whether both requested clips can be
    -- restored once RedM has built the native pair. Clips must still be set
    -- before the shared total or RedM adds the clip values to that total.
    Wait(100)
    local primaryClipSet = SetAmmoInClip(ped, weaponHash, primaryLoaded)
    local offhandClipSet = SetAmmoInClip(ped, offhandWeaponHash, offhandLoaded)
    SetPedAmmoByType(ped, ammoHash, total)
    SetCurrentPedWeapon(ped, weaponHash, true, primaryAttachPoint, false, false)

    local primaryClipOk, observedPrimary = GetAmmoInClip(ped, weaponHash)
    local offhandClipOk, observedOffhand = GetAmmoInClip(ped, offhandWeaponHash)
    local selected = CurrentWeapon(ped)
    local observedTotal = math.max(0,
        math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0))
    active = true
    print(('[WeaponNativeProbe] dual-prepare primary=%s offhand=%s selected=%s total=%d '
        .. 'primaryLoaded=%d primaryClipOk=%s primarySet=%s offhandLoaded=%d offhandClipOk=%s offhandSet=%s '
        .. 'attachPoints=%d/%d sameHash=%s grants=%s/%s stages=%s/%s'):format(
        weaponName, offhandWeaponName, tostring(selected), observedTotal,
        math.max(0, math.floor(tonumber(observedPrimary) or 0)), tostring(NativeTrue(primaryClipOk)),
        tostring(primaryClipSet), math.max(0, math.floor(tonumber(observedOffhand) or 0)),
        tostring(NativeTrue(offhandClipOk)), tostring(offhandClipSet), primaryAttachPoint,
        offhandAttachPoint, tostring(weaponHash == offhandWeaponHash),
        tostring(primaryGranted), tostring(offhandGranted), primaryStage, offhandStage))
end, false)

RegisterCommand('WeaponNativeProbeDualAllow', function(_, args)
    if RefuseInventoryWeapon() then return end
    local requested = tostring(args and args[1] or 'on'):lower()
    if requested == 'off' or requested == 'false' or requested == '0' then
        RestoreDualWieldState()
        return
    end

    local ped = PlayerPedId()
    if not dualOverride then
        dualOverride = {
            allowed = GetDualWieldAllowed(ped),
            unlocked = IsOffhandUnlocked(),
            visible = IsOffhandVisible()
        }
    end
    SetOffhandUnlocked(true)
    SetOffhandVisible(true)
    SetDualWieldAllowed(ped, true)
    print(('[WeaponNativeProbe] dual-allow requested=true allowed=%s unlocked=%s visible=%s'):format(
        tostring(GetDualWieldAllowed(ped)),
        tostring(IsOffhandUnlocked()),
        tostring(IsOffhandVisible())))
end, false)

RegisterCommand('WeaponNativeProbeDualEntitle', function()
    if RefuseInventoryWeapon() then return end
    local clothing = AddNativeWardrobeEntitlement(
        'CLOTHING_ITEM_M_OFFHAND_000_TINT_004', 0xF20B6B4A)
    local upgrade = AddNativeWardrobeEntitlement('UPGRADE_OFFHAND_HOLSTER', 0x39E57B01)
    local ped = PlayerPedId()
    SetDualWieldAllowed(ped, true)
    print(('[WeaponNativeProbe] dual-entitlement clothing=%s/%s existing=%s '
        .. 'upgrade=%s/%s existing=%s allowed=%s'):format(
        tostring(clothing.ok), tostring(clothing.stage or 'ready'), tostring(clothing.existing == true),
        tostring(upgrade.ok), tostring(upgrade.stage or 'ready'), tostring(upgrade.existing == true),
        tostring(GetDualWieldAllowed(ped))))
end, false)

RegisterCommand('WeaponNativeProbeDualStatus', function()
    local ped = PlayerPedId()
    local primaryClipOk, primaryLoaded = GetAmmoInClip(ped, weaponHash)
    local offhandClipOk, offhandLoaded = GetAmmoInClip(ped, offhandWeaponHash)
    local handOk, handWeapon = CurrentWeaponAt(ped, false, 0, true)
    local primaryOk, primaryWeapon = CurrentWeaponAt(ped, true, primaryAttachPoint, true)
    local offhandOk, offhandWeapon = CurrentWeaponAt(ped, true, offhandAttachPoint, true)
    local primaryEntity = GetCurrentPedWeaponEntityIndex(ped, primaryAttachPoint)
    local offhandEntity = GetCurrentPedWeaponEntityIndex(ped, offhandAttachPoint)
    print(('[WeaponNativeProbe] dual-status primary=%s offhand=%s selected=%s total=%d '
        .. 'primaryLoaded=%d primaryClipOk=%s primaryWeaponTotal=%d '
        .. 'offhandLoaded=%d offhandClipOk=%s offhandWeaponTotal=%d '
        .. 'hand=%s/%s attach%d=%s/%s entity=%s attach%d=%s/%s entity=%s'):format(
        weaponName, offhandWeaponName, tostring(CurrentWeapon(ped)),
        math.max(0, math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0)),
        math.max(0, math.floor(tonumber(primaryLoaded) or 0)), tostring(NativeTrue(primaryClipOk)),
        math.max(0, math.floor(tonumber(GetAmmoInPedWeapon(ped, weaponHash)) or 0)),
        math.max(0, math.floor(tonumber(offhandLoaded) or 0)), tostring(NativeTrue(offhandClipOk)),
        math.max(0, math.floor(tonumber(GetAmmoInPedWeapon(ped, offhandWeaponHash)) or 0)),
        tostring(handOk), tostring(handWeapon), primaryAttachPoint, tostring(primaryOk),
        tostring(primaryWeapon), tostring(primaryEntity), offhandAttachPoint, tostring(offhandOk),
        tostring(offhandWeapon), tostring(offhandEntity)))
end, false)

RegisterCommand('WeaponNativeProbeStatus', function(_, args)
    PrintSnapshot(args and args[1] or 'status', Snapshot())
end, false)

RegisterCommand('WeaponNativeProbeWatch', function()
    watching = not watching
    previous = Snapshot()
    print(('[WeaponNativeProbe] watch=%s intervalMs=%d'):format(tostring(watching), interval))
    if watching then PrintSnapshot('watch-start', previous) end
end, false)

RegisterCommand('WeaponNativeProbeMark', function(_, args)
    markCounter = markCounter + 1
    local name = args and args[1] or ('mark-' .. tostring(markCounter))
    marks[name] = Snapshot()
    PrintSnapshot('mark:' .. name, marks[name])
end, false)

RegisterCommand('WeaponNativeProbeCompare', function(_, args)
    local leftName, rightName = args and args[1], args and args[2]
    local left, right = leftName and marks[leftName], rightName and marks[rightName]
    if not left or not right then
        print('[WeaponNativeProbe] compare requires two existing mark names')
        return
    end
    print(('[WeaponNativeProbe] compare %s->%s pedChanged=%s selected=%s->%s dead=%s->%s '
        .. 'loaded=%+d weaponTotal=%+d ammoTypeTotal=%+d'):format(
        leftName, rightName, tostring(left.ped ~= right.ped), tostring(left.selected),
        tostring(right.selected), tostring(left.dead), tostring(right.dead),
        right.loaded - left.loaded, right.weaponTotal - left.weaponTotal,
        right.ammoTypeTotal - left.ammoTypeTotal))
end, false)

RegisterCommand('WeaponNativeProbeClear', function()
    if RefuseInventoryWeapon() then
        RemoveProbeEntitlements()
        RestoreDualWieldState()
        return
    end
    local ped = PlayerPedId()
    ClearNativeTestState(ped)
    RemoveProbeEntitlements()
    RestoreDualWieldState()
    offhandWeaponName = configuredOffhandWeaponName
    offhandWeaponHash = joaat(offhandWeaponName)
    active, watching, previous, marks, markCounter, logicalItem = false, false, nil, {}, 0, 'unlabeled'
    print('[WeaponNativeProbe] cleared')
end, false)

CreateThread(function()
    while true do
        if active and watching then
            local ok, current = pcall(Snapshot)
            if not ok then
                watching = false
                print(('[WeaponNativeProbe] observer stopped after snapshot error: %s'):format(tostring(current)))
            else
                if not Same(previous, current) then PrintSnapshot('transition', current) end
                previous = current
            end
            Wait(interval)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local hasInventoryWeapon = InventoryWeaponActive()
    if active and not hasInventoryWeapon then
        ClearNativeTestState(PlayerPedId())
    end
    RemoveProbeEntitlements()
    RestoreDualWieldState()
end)

print(('[WeaponNativeProbe] ready weapon=%s offhand=%s ammo=%s; isolated from production weapon leases'):format(
    weaponName, offhandWeaponName, ammoName))
