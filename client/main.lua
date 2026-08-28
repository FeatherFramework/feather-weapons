FeatherWeaponsClient = {}
local equipped, pendingToken, pendingNativeWeaponName = nil, nil, nil
local syncInFlight, desiredAmmo = false, nil
local reloadInFlight, reloadQueued = false, false
local reloadInputArmed = false
local unloadInFlight, unloadQueued = false, false
local inventoryWeaponInFlight = false
local attachmentReconcileUntil = 0
local BeginReload, BeginUnload

local function Notify(message)
    local result = exports["feather-core"]:ShowNotification({
        style = "right",
        message = message,
        duration = 3000
    })
    if (not result or result.ok ~= true) and Config.DevMode then
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

local function ApplyNativeAttachments(nativeWeaponName, attachments)
    local ped = PlayerPedId()
    local weaponHash = joaat(nativeWeaponName)
    for _, attachment in ipairs(attachments or {}) do
        local componentHash = joaat(attachment.nativeComponentName)
        local modelHash = Citizen.InvokeNative(0x59DE03442B6C9598, componentHash)
        if modelHash and modelHash ~= 0 then
            RequestModel(modelHash)
            local attempts = 0
            while not HasModelLoaded(modelHash) and attempts < 100 do
                attempts = attempts + 1
                Wait(0)
            end
        end
        Citizen.InvokeNative(0x74C9090FDD1BB48E, ped, componentHash, weaponHash, true)
        if modelHash and modelHash ~= 0 then SetModelAsNoLongerNeeded(modelHash) end
    end
end

local function ScheduleAttachmentReconciliation(nativeWeaponName, attachments)
    if not attachments or #attachments == 0 then return end
    attachmentReconcileUntil = GetGameTimer() + 15000
    for _, delay in ipairs({ 250, 1000 }) do
        SetTimeout(delay, function()
            local expected = (equipped and equipped.nativeWeaponName == nativeWeaponName)
                or pendingNativeWeaponName == nativeWeaponName
            if expected then ApplyNativeAttachments(nativeWeaponName, attachments) end
        end)
    end
end

local function GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, attachments)
    local ped = PlayerPedId()
    local ammoHash = nativeAmmoName and joaat(nativeAmmoName) or nil
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local before = ammoHash and GetPedAmmoByType(ped, ammoHash) or nil
    GiveWeaponToPed(ped, joaat(nativeWeaponName), amount, false, true)
    ApplyNativeAttachments(nativeWeaponName, attachments)
    ScheduleAttachmentReconciliation(nativeWeaponName, attachments)
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

local function RestoreApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, attachments)
    RemoveWeaponFromPed(PlayerPedId(), joaat(nativeWeaponName))
    ResetNativeAmmo("ammo-restored", nativeAmmoName)
    GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, attachments)
end

local function ClearNativeWeapon()
    local nativeWeaponName = equipped and equipped.nativeWeaponName or pendingNativeWeaponName
    local nativeAmmoName = equipped and equipped.nativeAmmoName or nil
    if nativeWeaponName then RemoveWeaponFromPed(PlayerPedId(), joaat(nativeWeaponName)) end
    ResetNativeAmmo("weapon-cleared", nativeAmmoName)
    equipped, pendingToken, pendingNativeWeaponName, desiredAmmo, syncInFlight = nil, nil, nil, nil, false
    reloadInFlight, reloadQueued = false, false
    unloadInFlight, unloadQueued = false, false
    attachmentReconcileUntil = 0
end

local function ApplyApprovedWeapon(approved)
    local alreadyApplied = (equipped and SameInstance(equipped.itemInstanceId, approved.itemInstanceId))
        or (pendingNativeWeaponName == approved.nativeWeaponName)
    if not alreadyApplied then
        ClearNativeWeapon()
        GiveApprovedNativeWeapon(approved.nativeWeaponName, approved.nativeAmmoName, approved.ammo, approved.attachments)
    end
    equipped = { itemInstanceId = approved.itemInstanceId, definitionId = approved.definitionId,
        nativeWeaponName = approved.nativeWeaponName, nativeAmmoName = approved.nativeAmmoName,
        ammo = tonumber(approved.ammo) or 0, condition = tonumber(approved.condition),
        attachments = approved.attachments or {} }
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
        GiveApprovedNativeWeapon(authorization.nativeWeaponName, authorization.nativeAmmoName, authorization.ammo, authorization.attachments)
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
    local ped = PlayerPedId()
    if ped == 0 or GetEntityHealth(ped) <= 0 or IsEntityDead(ped) then
        reloadQueued = false
        return
    end
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

local function IsCarryingEntity(ped)
    if ped == 0 then return false end
    local carried = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped)
    if carried and carried ~= 0 then return true end
    return Citizen.InvokeNative(0xA911EE21EDF69DAF, ped) == true
end

local function HasNearbyCarryablePed(ped)
    local origin = GetEntityCoords(ped)
    for _, candidate in ipairs(GetGamePool('CPed')) do
        if candidate ~= ped and DoesEntityExist(candidate) then
            local coords = GetEntityCoords(candidate)
            if #(origin - coords) <= 2.25 then
                local carryable = IsEntityDead(candidate)
                    or (type(IsPedDeadOrDying) == 'function' and IsPedDeadOrDying(candidate, true))
                    or (type(IsPedHogtied) == 'function' and IsPedHogtied(candidate))
                if carryable then return true end
            end
        end
    end
    return false
end

local function CarryInteractionActive(ped)
    return IsCarryingEntity(ped) or HasNearbyCarryablePed(ped)
end

function FeatherWeaponsClient.Unload(amount, callback)
    FeatherCore.RPC.Call("feather-weapons:ammo:unload", { amount = amount }, function(result, rpcError)
        if result and result.ok and equipped then
            equipped.ammo = tonumber(result.value.loaded) or 0
            desiredAmmo = equipped.ammo
            RestoreApprovedNativeWeapon(equipped.nativeWeaponName,
                result.value.nativeAmmoName or equipped.nativeAmmoName, equipped.ammo, equipped.attachments)
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

local function HandleAttachmentResult(result)
    if result and result.ok and equipped then
        equipped.attachments = result.value.attachments or {}
        RestoreApprovedNativeWeapon(equipped.nativeWeaponName, equipped.nativeAmmoName, equipped.ammo,
            equipped.attachments)
        Notify(result.value.installed and "Attachment installed." or "Attachment removed.")
        return
    end
    local failure = result and result.error
    Notify(failure and failure.message or "Unable to modify this weapon.")
end

RegisterNetEvent("feather-weapons:client:attachmentResult", HandleAttachmentResult)

local ModificationMenu = FeatherMenu:RegisterMenu("feather-weapons:modifications", {
    top = "10%",
    left = "5%",
    ["720width"] = "360px",
    ["1080width"] = "420px",
    ["2kwidth"] = "500px",
    ["4kwidth"] = "650px",
    draggable = true,
    canclose = true
}, {})

local ModificationPage = nil

local function NearGunsmithStation()
    local settings = Config.Attachments or {}
    if settings.requireStation ~= true then return true end
    local position = GetEntityCoords(PlayerPedId())
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

local function OpenModificationMenu()
    if not equipped then
        Notify("Equip a weapon before modifying it.")
        return
    end
    if not NearGunsmithStation() then
        Notify("Visit a gunsmith bench to modify this weapon.")
        return
    end
    if ModificationPage then ModificationPage:UnRegister() end
    ModificationPage = ModificationMenu:RegisterPage("feather-weapons:installed-attachments")
    ModificationPage:RegisterElement("header", { value = "Weapon Modifications", slot = "header" })
    ModificationPage:RegisterElement("subheader", { value = equipped.definitionId or "Equipped weapon", slot = "header" })
    ModificationPage:RegisterElement("line", { slot = "header" })

    if not equipped.attachments or #equipped.attachments == 0 then
        ModificationPage:RegisterElement("textdisplay", { value = "No attachments are installed.", slot = "content" })
    else
        for _, installed in ipairs(equipped.attachments) do
            local attachmentId = installed.definitionId
            ModificationPage:RegisterElement("button", {
                label = ("Remove %s"):format(attachmentId:gsub("_", " ")),
                slot = "content"
            }, function()
                ModificationMenu:Close()
                FeatherCore.RPC.Call("feather-weapons:attachment:remove", { attachmentId = attachmentId },
                    function(result, rpcError)
                        HandleAttachmentResult(result or { ok = false, error = rpcError })
                    end)
            end)
        end
    end
    ModificationMenu:Open({ startupPage = ModificationPage })
end

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

    if reloadControl.disableNative and reloadControl.nativeControl then
        CreateThread(function()
            while true do
                if equipped then
                    DisableControlAction(0, reloadControl.nativeControl, true)
                    if IsDisabledControlJustPressed(0, reloadControl.nativeControl) then
                        reloadInputArmed = not CarryInteractionActive(PlayerPedId())
                    end
                    if IsDisabledControlJustReleased(0, reloadControl.nativeControl) then
                        local shouldReload = reloadInputArmed and not CarryInteractionActive(PlayerPedId())
                        reloadInputArmed = false
                        if shouldReload then BeginReload() end
                    end
                    Wait(0)
                else
                    reloadInputArmed = false
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

if Config.Controls and Config.Controls.modify and Config.Controls.modify.enabled then
    local modifyControl = Config.Controls.modify
    RegisterCommand(modifyControl.command, OpenModificationMenu, false)
    RegisterKeyMapping(modifyControl.command, "Modify equipped weapon", "keyboard", modifyControl.defaultKey or "F6")
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

AddEventHandler("Feather:Character:Spawned", function()
    FeatherWeaponsClient.Reconcile()
    SetTimeout(2000, function() FeatherWeaponsClient.Reconcile() end)
    SetTimeout(5000, function() FeatherWeaponsClient.Reconcile() end)
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
