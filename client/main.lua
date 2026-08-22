FeatherWeaponsClient = {}
local equipped, pendingToken, pendingNativeWeaponName, activeCharacterId = nil, nil, nil, nil
local syncInFlight, desiredAmmo = false, nil

local function SetNativeAmmo(nativeAmmoName, amount)
    if not nativeAmmoName then return end
    local ped = PlayerPedId()
    local ammoHash = joaat(nativeAmmoName)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local before = GetPedAmmoByType(ped, ammoHash)
    if before < amount then
        Citizen.InvokeNative(0x5FD1E1F011E76D7E, ped, ammoHash, amount)
    end
    if Config.DevMode then
        print(("[feather-weapons] native ammo target=%s before=%s after=%s"):format(
            tostring(amount), tostring(before), tostring(GetPedAmmoByType(ped, ammoHash))))
    end
end
local function ClearNativeWeapon()
    local nativeWeaponName = equipped and equipped.nativeWeaponName or pendingNativeWeaponName
    if nativeWeaponName then RemoveWeaponFromPed(PlayerPedId(), joaat(nativeWeaponName)) end
    equipped, pendingToken, pendingNativeWeaponName, desiredAmmo, syncInFlight = nil, nil, nil, nil, false
end

local function ApplyApprovedWeapon(approved)
    if not equipped or equipped.itemInstanceId ~= approved.itemInstanceId then
        ClearNativeWeapon()
        GiveWeaponToPed(PlayerPedId(), joaat(approved.nativeWeaponName), tonumber(approved.ammo) or 0, false, true)
    end
    SetNativeAmmo(approved.nativeAmmoName, approved.ammo)
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
        if desiredAmmo < equipped.ammo then FlushConsumption() end
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
        GiveWeaponToPed(PlayerPedId(), nativeHash, tonumber(authorization.ammo) or 0, false, true)
        SetNativeAmmo(authorization.nativeAmmoName, authorization.ammo)
        FeatherCore.RPC.Call("feather-weapons:equip:acknowledge", { token = authorization.token }, function(ack, ackError)
            if not ack or not ack.ok then
                RemoveWeaponFromPed(PlayerPedId(), nativeHash)
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
            SetNativeAmmo(result.value.nativeAmmoName or equipped.nativeAmmoName, equipped.ammo)
        end
        if callback then callback(result, rpcError) end
    end)
end

function FeatherWeaponsClient.Reload(amount, callback) AmmoOperation("feather-weapons:ammo:reload", amount, callback) end

function FeatherWeaponsClient.Repair(itemInstanceId, callback)
    FeatherCore.RPC.Call("feather-weapons:repair", { itemInstanceId = itemInstanceId }, function(result, rpcError)
        if result and result.ok and equipped and equipped.itemInstanceId == itemInstanceId then
            equipped.condition = tonumber(result.value.condition) or equipped.condition
        end
        if callback then callback(result, rpcError) end
    end)
end

RegisterNetEvent("feather-weapons:client:clearAuthorization", function(token) if pendingToken == token then ClearNativeWeapon() end end)
RegisterNetEvent("feather-weapons:client:clearEquipped", ClearNativeWeapon)
RegisterNetEvent("feather-weapons:client:clearSession", ClearNativeWeapon)
RegisterNetEvent("feather-weapons:client:reconcile", function() FeatherWeaponsClient.Reconcile() end)

CreateThread(function()
    while true do
        if equipped and desiredAmmo and desiredAmmo > 0 and IsPedShooting(PlayerPedId()) then
            local itemInstanceId = equipped.itemInstanceId
            local ammoHash = equipped.nativeAmmoName and joaat(equipped.nativeAmmoName) or nil
            Wait(75)
            if equipped and equipped.itemInstanceId == itemInstanceId and ammoHash then
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

AddEventHandler("Feather:Character:Spawned", function(character)
    activeCharacterId = character and character.id or nil
    FeatherWeaponsClient.Reconcile()
end)
AddEventHandler("Feather:Character:Logout", function() activeCharacterId = nil ClearNativeWeapon() end)
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then SetTimeout(1000, function() FeatherWeaponsClient.Reconcile() end) end
end)
AddEventHandler("onResourceStop", function(resourceName) if resourceName == GetCurrentResourceName() then ClearNativeWeapon() end end)

if Config.DevMode and Config.Inventory.allowTestAdapter then
    RegisterCommand("testweapon", function()
        if activeCharacterId then FeatherWeaponsClient.Equip(("dev:cattleman:%s"):format(tostring(activeCharacterId))) end
    end, false)
    RegisterCommand("testweaponoff", function() FeatherWeaponsClient.Unequip() end, false)
    RegisterCommand("testweaponstate", function()
        FeatherWeaponsClient.Reconcile(function(result, rpcError)
            if result and result.ok then
                local state = result.value.equipped
                print(("[feather-weapons] state equipped=%s loaded=%s condition=%s"):format(
                    tostring(state ~= nil), tostring(state and state.ammo), tostring(state and state.condition)))
            else
                local failure = result and result.error or rpcError
                print(("[feather-weapons] state failed: %s"):format(failure and tostring(failure.code) or "no response"))
            end
        end)
    end, false)
    local function PrintAmmoResult(action, result, rpcError)
        if result and result.ok then
            print(("[feather-weapons] %s moved=%s loaded=%s reserve=%s"):format(action,
                tostring(result.value.moved), tostring(result.value.loaded), tostring(result.value.inventoryAmmo)))
            return
        end
        local failure = result and result.error or rpcError
        print(("[feather-weapons] %s failed: %s"):format(action,
            failure and (tostring(failure.code) .. " - " .. tostring(failure.message)) or "no response"))
    end
    RegisterCommand("testreload", function(_, args)
        FeatherWeaponsClient.Reload(args[1], function(result, rpcError) PrintAmmoResult("reload", result, rpcError) end)
    end, false)
    RegisterCommand("testrepair", function()
        if not activeCharacterId then return end
        local itemInstanceId = ("dev:cattleman:%s"):format(tostring(activeCharacterId))
        FeatherWeaponsClient.Repair(itemInstanceId, function(result, rpcError)
            if result and result.ok then
                print(("[feather-weapons] repair restored=%s condition=%s kits=%s"):format(
                    tostring(result.value.restored), tostring(result.value.condition), tostring(result.value.materialRemaining)))
                return
            end
            local failure = result and result.error or rpcError
            print(("[feather-weapons] repair failed: %s"):format(
                failure and (tostring(failure.code) .. " - " .. tostring(failure.message)) or "no response"))
        end)
    end, false)
end

exports("initiate", function() return FeatherWeaponsClient end)
FeatherWeaponsClientReady = true
