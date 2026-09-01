local settings = Config.NativeProbe or {}
if Config.DevMode ~= true or settings.enabled ~= true then return end

local weaponName = settings.weapon or 'WEAPON_REVOLVER_CATTLEMAN'
local ammoName = settings.ammo or 'AMMO_REVOLVER'
local weaponHash = joaat(weaponName)
local ammoHash = joaat(ammoName)
local capacity = math.max(1, math.floor(tonumber(settings.capacity) or 6))
local interval = math.max(25, math.floor(tonumber(settings.observationIntervalMs) or 50))
local active = false
local watching = false
local previous = nil
local marks = {}
local markCounter = 0
local logicalItem = 'unlabeled'
local nativeRemoveReason = joaat('REMOVE_REASON_CLIENT_PURGED')

local function NativeTrue(value)
    return value == true or value == 1
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
    RemoveWeaponFromPed(ped, weaponHash, true, nativeRemoveReason)
    local afterWeaponRemoval = math.max(0,
        math.floor(tonumber(GetPedAmmoByType(ped, ammoHash)) or 0))
    print(('[WeaponNativeProbe] cleanup requested=%d afterType=%d afterWeapon=%d'):format(
        amount, afterTypeRemoval, afterWeaponRemoval))
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
    GiveWeaponToPed(
        ped,
        weaponHash,
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
    if RefuseInventoryWeapon() then return end
    local ped = PlayerPedId()
    ClearNativeTestState(ped)
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
    if resource ~= GetCurrentResourceName() or not active then return end
    local hasInventoryWeapon = InventoryWeaponActive()
    if hasInventoryWeapon then return end
    local ped = PlayerPedId()
    ClearNativeTestState(ped)
end)

print(('[WeaponNativeProbe] ready weapon=%s ammo=%s; isolated from production weapon leases'):format(
    weaponName, ammoName))
