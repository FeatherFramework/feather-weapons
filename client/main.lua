FeatherWeaponsClient = {}
local equipped, pendingToken, pendingNativeWeaponName = nil, nil, nil
local syncInFlight, desiredAmmo = false, nil
local reloadInFlight, reloadQueued = false, false
local unloadInFlight, unloadQueued = false, false
local inventoryWeaponInFlight = false
local BeginReload, BeginUnload

local function Notify(message)
    if FeatherCore and FeatherCore.Notify and FeatherCore.Notify.RightNotify then
        FeatherCore.Notify.RightNotify(message, 3000)
    elseif Config.DevMode then
        print(("[feather-weapons] %s"):format(message))
    end
end

local function SameInstance(left, right)
    return left ~= nil and right ~= nil and tostring(left) == tostring(right)
end

local function SetNativeAmmo(nativeAmmoName, amount, nativeWeaponName)
    if not nativeAmmoName then return end
    local ped = PlayerPedId()
    local ammoHash = joaat(nativeAmmoName)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local before = GetPedAmmoByType(ped, ammoHash)
    if nativeWeaponName then
        Citizen.InvokeNative(0xDCD2A934D65CB497, ped, joaat(nativeWeaponName), math.min(before, amount))
    end
    if before < amount then
        Citizen.InvokeNative(0x5FD1E1F011E76D7E, ped, ammoHash, amount)
    end
    if Config.DevMode then
        print(("[feather-weapons] native ammo target=%s before=%s after=%s"):format(
            tostring(amount), tostring(before), tostring(GetPedAmmoByType(ped, ammoHash))))
    end
end

local function GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount)
    local ped = PlayerPedId()
    local ammoHash = nativeAmmoName and joaat(nativeAmmoName) or nil
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local before = ammoHash and GetPedAmmoByType(ped, ammoHash) or nil
    GiveWeaponToPed(ped, joaat(nativeWeaponName), amount, false, true)
    if Config.DevMode then
        local after = ammoHash and GetPedAmmoByType(ped, ammoHash) or nil
        print(("[feather-weapons] native weapon granted loaded=%s before=%s after=%s"):format(
            tostring(amount), tostring(before), tostring(after)))
    end
end

local function ResetNativeAmmo(reason, nativeAmmoName)
    if not (Config.Runtime and Config.Runtime.authoritativeNativeAmmo) then return end
    local ped = PlayerPedId()
    local before = nativeAmmoName and GetPedAmmoByType(ped, joaat(nativeAmmoName)) or nil
    Citizen.InvokeNative(0x1B83C0DEEBCBB214, ped)
    if Config.DevMode then
        local after = nativeAmmoName and GetPedAmmoByType(ped, joaat(nativeAmmoName)) or nil
        print(("[feather-weapons] native ammo reset reason=%s before=%s after=%s"):format(
            tostring(reason), tostring(before), tostring(after)))
    end
end

local function RestoreApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount)
    RemoveWeaponFromPed(PlayerPedId(), joaat(nativeWeaponName))
    ResetNativeAmmo("ammo-restored", nativeAmmoName)
    GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount)
end

local function ClearNativeWeapon()
    local nativeWeaponName = equipped and equipped.nativeWeaponName or pendingNativeWeaponName
    local nativeAmmoName = equipped and equipped.nativeAmmoName or nil
    if nativeWeaponName then RemoveWeaponFromPed(PlayerPedId(), joaat(nativeWeaponName)) end
    ResetNativeAmmo("weapon-cleared", nativeAmmoName)
    equipped, pendingToken, pendingNativeWeaponName, desiredAmmo, syncInFlight = nil, nil, nil, nil, false
    reloadInFlight, reloadQueued = false, false
    unloadInFlight, unloadQueued = false, false
end

local function ApplyApprovedWeapon(approved)
    local alreadyApplied = (equipped and SameInstance(equipped.itemInstanceId, approved.itemInstanceId))
        or (pendingNativeWeaponName == approved.nativeWeaponName)
    if not alreadyApplied then
        ClearNativeWeapon()
        GiveApprovedNativeWeapon(approved.nativeWeaponName, approved.nativeAmmoName, approved.ammo)
    end
    equipped = { itemInstanceId = approved.itemInstanceId, definitionId = approved.definitionId,
        nativeWeaponName = approved.nativeWeaponName, nativeAmmoName = approved.nativeAmmoName,
        ammo = tonumber(approved.ammo) or 0, condition = tonumber(approved.condition) }
    desiredAmmo = equipped.ammo
end

local function FlushConsumption()
    if syncInFlight or not equipped or desiredAmmo == nil or desiredAmmo >= equipped.ammo then return end
    syncInFlight = true
    local submitted = desiredAmmo
    FeatherCore.RPC.Call("feather-weapons:ammo:sync", { loaded = submitted }, function(result)
        syncInFlight = false
        if not equipped then return end
        if result and result.ok then
            equipped.ammo = tonumber(result.value.loaded) or submitted
            equipped.condition = tonumber(result.value.condition) or equipped.condition
            if Config.DevMode then
                print(("[feather-weapons] fired consumed=%s loaded=%s condition=%s"):format(
                    tostring(result.value.consumed), tostring(equipped.ammo), tostring(equipped.condition)))
            end
            if result.value.broken then
                print("[feather-weapons] weapon condition is broken")
                ClearNativeWeapon()
                return
            end
            if desiredAmmo > equipped.ammo then desiredAmmo = equipped.ammo end
        else
            FeatherWeaponsClient.Reconcile()
            return
        end
        if desiredAmmo < equipped.ammo then
            FlushConsumption()
        elseif reloadQueued then
            reloadQueued = false
            BeginReload()
        elseif unloadQueued then
            unloadQueued = false
            BeginUnload()
        end
    end)
end

function FeatherWeaponsClient.Reconcile(callback)
    FeatherCore.RPC.Call("feather-weapons:state:get", {}, function(result, rpcError)
        if not result or not result.ok then if callback then callback(result, rpcError) end return end
        if result.value.equipped then ApplyApprovedWeapon(result.value.equipped) else ClearNativeWeapon() end
        if callback then callback(result) end
    end)
end

function FeatherWeaponsClient.Equip(itemInstanceId, callback)
    FeatherCore.RPC.Call("feather-weapons:equip:request", { itemInstanceId = itemInstanceId }, function(result, rpcError)
        if not result or not result.ok then if callback then callback(result, rpcError) end return end
        local authorization = result.value
        pendingToken, pendingNativeWeaponName = authorization.token, authorization.nativeWeaponName

        local nativeHash = joaat(authorization.nativeWeaponName)
        ResetNativeAmmo("weapon-equipped", authorization.nativeAmmoName)
        GiveApprovedNativeWeapon(authorization.nativeWeaponName, authorization.nativeAmmoName, authorization.ammo)
        FeatherCore.RPC.Call("feather-weapons:equip:acknowledge", { token = authorization.token }, function(ack, ackError)
            if not ack or not ack.ok then
                RemoveWeaponFromPed(PlayerPedId(), nativeHash)
                ResetNativeAmmo("equip-rejected", authorization.nativeAmmoName)
                pendingToken, pendingNativeWeaponName = nil, nil
                if callback then callback(ack, ackError) end
                return
            end
            ApplyApprovedWeapon(ack.value)
            pendingToken, pendingNativeWeaponName = nil, nil
            if callback then callback(ack) end
        end)
    end)
end

function FeatherWeaponsClient.Unequip(callback)
    FeatherCore.RPC.Call("feather-weapons:equip:unequip", {}, function(result, rpcError)
        if result and result.ok then ClearNativeWeapon() end
        if callback then callback(result, rpcError) end
    end)
end

local function AmmoOperation(route, amount, callback)
    FeatherCore.RPC.Call(route, { amount = amount }, function(result, rpcError)
        if result and result.ok and equipped then
            equipped.ammo = tonumber(result.value.loaded) or equipped.ammo
            desiredAmmo = equipped.ammo
            SetNativeAmmo(result.value.nativeAmmoName or equipped.nativeAmmoName, equipped.ammo, equipped.nativeWeaponName)
        end
        if callback then callback(result, rpcError) end
    end)
end

function FeatherWeaponsClient.Reload(amount, callback) AmmoOperation("feather-weapons:ammo:reload", amount, callback) end

BeginReload = function()
    if reloadInFlight then return end
    if not equipped then
        Notify("No weapon is equipped.")
        return
    end
    if syncInFlight or (desiredAmmo ~= nil and desiredAmmo < equipped.ammo) then
        reloadQueued = true
        FlushConsumption()
        return
    end

    reloadInFlight = true
    FeatherWeaponsClient.Reload(nil, function(result, rpcError)
        reloadInFlight = false
        if result and result.ok then
            local ped = PlayerPedId()
            if not IsPedReloading(ped) then
                Citizen.InvokeNative(0x62D2916F56B9CD2D, ped, true)
            end
            Notify(("Loaded %s round%s."):format(
                tostring(result.value.moved), result.value.moved == 1 and "" or "s"))
            return
        end
        local failure = result and result.error or rpcError
        Notify(failure and failure.message or "Unable to reload.")
    end)
end

function FeatherWeaponsClient.Unload(amount, callback)
    FeatherCore.RPC.Call("feather-weapons:ammo:unload", { amount = amount }, function(result, rpcError)
        if result and result.ok and equipped then
            equipped.ammo = tonumber(result.value.loaded) or 0
            desiredAmmo = equipped.ammo
            RestoreApprovedNativeWeapon(equipped.nativeWeaponName,
                result.value.nativeAmmoName or equipped.nativeAmmoName, equipped.ammo)
        end
        if callback then callback(result, rpcError) end
    end)
end

BeginUnload = function()
    if unloadInFlight then return end
    if not equipped then
        Notify("No weapon is equipped.")
        return
    end
    if syncInFlight or (desiredAmmo ~= nil and desiredAmmo < equipped.ammo) then
        unloadQueued = true
        FlushConsumption()
        return
    end

    unloadInFlight = true
    FeatherWeaponsClient.Unload(nil, function(result, rpcError)
        unloadInFlight = false
        if result and result.ok then
            Notify(("Unloaded %s round%s."):format(
                tostring(result.value.moved), result.value.moved == 1 and "" or "s"))
            return
        end
        local failure = result and result.error or rpcError
        Notify(failure and failure.message or "Unable to unload.")
    end)
end

function FeatherWeaponsClient.Repair(itemInstanceId, callback)
    FeatherCore.RPC.Call("feather-weapons:repair", { itemInstanceId = itemInstanceId }, function(result, rpcError)
        if result and result.ok and equipped and SameInstance(equipped.itemInstanceId, itemInstanceId) then
            equipped.condition = tonumber(result.value.condition) or equipped.condition
        end
        if callback then callback(result, rpcError) end
    end)
end


RegisterNetEvent("feather-weapons:client:useInventoryWeapon", function(itemInstanceId)
    if inventoryWeaponInFlight then return end
    if Config.DevMode then
        print(("[feather-weapons] inventory weapon requested item=%s"):format(tostring(itemInstanceId)))
    end

    if equipped and not SameInstance(equipped.itemInstanceId, itemInstanceId) then
        Notify("Unequip the current weapon before equipping another.")
        return
    end

    inventoryWeaponInFlight = true
    if equipped then
        FeatherWeaponsClient.Unequip(function(result, rpcError)
            inventoryWeaponInFlight = false
            if result and result.ok then
                Notify("Weapon unequipped.")
                return
            end
            local failure = result and result.error or rpcError
            Notify(failure and failure.message or "Unable to unequip this weapon.")
        end)
        return
    end

    FeatherWeaponsClient.Equip(itemInstanceId, function(result, rpcError)
        inventoryWeaponInFlight = false
        if result and result.ok then
            Notify("Weapon equipped.")
            if Config.DevMode then
                print(("[feather-weapons] inventory equip succeeded item=%s"):format(tostring(itemInstanceId)))
            end
            return
        end
        local failure = result and result.error or rpcError
        Notify(failure and failure.message or "Unable to equip this weapon.")
        if Config.DevMode then
            print(("[feather-weapons] inventory equip failed item=%s code=%s message=%s"):format(
                tostring(itemInstanceId), tostring(failure and failure.code), tostring(failure and failure.message)))
        end
    end)
end)

RegisterNetEvent("feather-weapons:client:inventoryRepairResult", function(result)
    if result and result.ok then
        if equipped and SameInstance(equipped.itemInstanceId, result.value.itemInstanceId) then
            equipped.condition = tonumber(result.value.condition) or equipped.condition
        end
        Notify(("Weapon repaired by %s%%."):format(tostring(result.value.restored)))
        return
    end
    local failure = result and result.error
    Notify(failure and failure.message or "Unable to repair this weapon.")
end)

RegisterNetEvent("feather-weapons:client:clearAuthorization", function(token) if pendingToken == token then ClearNativeWeapon() end end)
RegisterNetEvent("feather-weapons:client:clearEquipped", ClearNativeWeapon)
RegisterNetEvent("feather-weapons:client:clearSession", ClearNativeWeapon)
RegisterNetEvent("feather-weapons:client:reconcile", function() FeatherWeaponsClient.Reconcile() end)

if Config.Controls and Config.Controls.reload and Config.Controls.reload.enabled then
    local reloadControl = Config.Controls.reload
    RegisterCommand(reloadControl.command, function() BeginReload() end, false)
    RegisterKeyMapping(reloadControl.command, "Reload equipped weapon", "keyboard", reloadControl.defaultKey or "R")

    if reloadControl.disableNative and reloadControl.nativeControl then
        CreateThread(function()
            while true do
                if equipped then
                    DisableControlAction(0, reloadControl.nativeControl, true)
                    Wait(0)
                else
                    Wait(500)
                end
            end
        end)
    end
end

if Config.Controls and Config.Controls.unload and Config.Controls.unload.enabled then
    local unloadControl = Config.Controls.unload
    RegisterCommand(unloadControl.command, function() BeginUnload() end, false)
    RegisterKeyMapping(unloadControl.command, "Unload equipped weapon", "keyboard", unloadControl.defaultKey or "U")
end

CreateThread(function()
    while true do
        if equipped and desiredAmmo and desiredAmmo > 0 and IsPedShooting(PlayerPedId()) then
            local itemInstanceId = equipped.itemInstanceId
            local ammoHash = equipped.nativeAmmoName and joaat(equipped.nativeAmmoName) or nil
            Wait(75)
            if equipped and SameInstance(equipped.itemInstanceId, itemInstanceId) and ammoHash then
                local observed = math.max(0, math.floor(tonumber(GetPedAmmoByType(PlayerPedId(), ammoHash)) or 0))
                if observed < desiredAmmo then
                    desiredAmmo = observed
                    SetTimeout(250, FlushConsumption)
                end
            end
        else
            Wait(equipped and 0 or 500)
        end
    end
end)

AddEventHandler("Feather:Character:Spawned", function()
    FeatherWeaponsClient.Reconcile()
end)
AddEventHandler("Feather:Character:Logout", function()
    inventoryWeaponInFlight = false
    ClearNativeWeapon()
end)
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then SetTimeout(1000, function() FeatherWeaponsClient.Reconcile() end) end
end)
AddEventHandler("onResourceStop", function(resourceName) if resourceName == GetCurrentResourceName() then ClearNativeWeapon() end end)

if Config.DevMode then
    RegisterCommand("weaponstate", function()
        FeatherWeaponsClient.Reconcile(function(result, rpcError)
            if result and result.ok then
                local state = result.value.equipped
                print(("[feather-weapons] state equipped=%s item=%s loaded=%s condition=%s"):format(
                    tostring(state ~= nil), tostring(state and state.itemInstanceId),
                    tostring(state and state.ammo), tostring(state and state.condition)))
                return
            end
            local failure = result and result.error or rpcError
            print(("[feather-weapons] state failed: %s"):format(
                failure and (tostring(failure.code) .. " - " .. tostring(failure.message)) or "no response"))
        end)
    end, false)
end
exports("initiate", function() return FeatherWeaponsClient end)
FeatherWeaponsClientReady = true
