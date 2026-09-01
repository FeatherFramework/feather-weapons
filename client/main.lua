FeatherWeaponsClient = {}
local equipped, pendingToken, pendingNativeWeaponName = nil, nil, nil
local syncInFlight, desiredAmmo, desiredLoaded = false, nil, nil
local unloadInFlight, unloadQueued = false, false
local inventoryWeaponInFlight = false
local attachmentReconcileUntil = 0
local BeginUnload
local RegisterCharacterLogoutCheckpoint
local observerCorrectionPending = false
local checkpointWaiters = {}
local nativeRemoveReason = joaat('REMOVE_REASON_CLIENT_PURGED')

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
        return exports["feather-notify"]:ShowNotification({
            style = "right",
            message = message,
            duration = 3000
        })
    end)

    if not called then
        result = { ok = false, code = "provider_unavailable" }
    end

    if (not result or result.ok ~= true) and Config.DevMode then
        print(("[feather-weapons] %s"):format(message))
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
        print(("[feather-weapons] native ammo target=%s before=%s after=%s"):format(
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
        print(("[feather-weapons] native weapon granted total=%s before=%s after=%s"):format(
            tostring(amount), tostring(before), tostring(after)))
    end
end

local function ResetNativeAmmo(reason, nativeAmmoName)
    if not (Config.Runtime and Config.Runtime.authoritativeNativeAmmo) then return end

    local ped = PlayerPedId()
    local before = nativeAmmoName and GetPedAmmoByType(ped, joaat(nativeAmmoName)) or nil
    Citizen.InvokeNative(0x1B83C0DEEBCBB214, ped) -- RemoveAllPedAmmo
    if Config.DevMode then
        local after = nativeAmmoName and GetPedAmmoByType(ped, joaat(nativeAmmoName)) or nil
        print(("[feather-weapons] native ammo reset reason=%s before=%s after=%s"):format(
            tostring(reason), tostring(before), tostring(after)))
    end
end

local function RestoreApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, loaded, attachments)
    RemoveNativeWeapon(PlayerPedId(), joaat(nativeWeaponName))
    ResetNativeAmmo("ammo-restored", nativeAmmoName)
    GiveApprovedNativeWeapon(nativeWeaponName, nativeAmmoName, amount, loaded, attachments)
end

local function ClearNativeWeapon()
    local nativeWeaponName = equipped and equipped.nativeWeaponName or pendingNativeWeaponName
    local nativeAmmoName = equipped and equipped.nativeAmmoName or nil
    if nativeWeaponName then
        RemoveNativeWeapon(PlayerPedId(), joaat(nativeWeaponName))
    end

    ResetNativeAmmo("weapon-cleared", nativeAmmoName)
    equipped, pendingToken, pendingNativeWeaponName, desiredAmmo, desiredLoaded, syncInFlight = nil, nil, nil, nil, nil, false
    unloadInFlight, unloadQueued = false, false
    observerCorrectionPending = false
    ResolveCheckpointWaiters({ ok = false, code = "session_cleared", message = "Weapon session was cleared." })
    attachmentReconcileUntil = 0
end

local function ApplyApprovedWeapon(approved)
    local alreadyApplied = (equipped and SameInstance(equipped.itemInstanceId, approved.itemInstanceId))
        or (pendingNativeWeaponName == approved.nativeWeaponName)
    if not alreadyApplied then
        ClearNativeWeapon()
        GiveApprovedNativeWeapon(approved.nativeWeaponName, approved.nativeAmmoName, approved.ammo,
            approved.loaded, approved.attachments)
    end

    equipped = {
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
        ResolveCheckpointWaiters({ ok = false, code = "invalid_native_state", message =
        "Native ammunition state is invalid." })
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
    FeatherCore.RPC.Call("feather-weapons:ammo:sync", {
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
                print(("[feather-weapons] checkpoint consumed=%s total=%s loaded=%s condition=%s"):format(
                    tostring(result.value.consumed), tostring(equipped.ammo),
                    tostring(equipped.loaded), tostring(equipped.condition)))
            end

            if result.value.broken then
                print("[feather-weapons] weapon condition is broken")
                ClearNativeWeapon()
                return
            end

            if desiredAmmo > equipped.ammo then desiredAmmo = equipped.ammo end
        else
            ResolveCheckpointWaiters(result or {
                ok = false,
                code = "checkpoint_failed",
                message = "Weapon state could not be saved."
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
        desiredLoaded = math.max(0, math.min(observedTotal,
            math.floor(tonumber(clipAmount) or 0)))
    end

    return true
end

function FeatherWeaponsClient.Checkpoint(callback)
    callback = type(callback) == "function" and callback or function() end

    checkpointWaiters[#checkpointWaiters + 1] = callback
    if not CaptureNativeState() then
        ResolveCheckpointWaiters({
            ok = false,
            code = "invalid_native_state",
            message = "Native ammunition exceeded the active weapon lease."
        })
        return
    end

    FlushConsumption()
end

function FeatherWeaponsClient.Reconcile(callback)
    FeatherCore.RPC.Call("feather-weapons:state:get", {}, function(result, rpcError)
        if not result or not result.ok then
            if callback then
                callback(result, rpcError)
            end
            return
        end

        if result.value.equipped then
            ApplyApprovedWeapon(result.value.equipped)
        else
            ClearNativeWeapon()
        end

        if callback then
            callback(result)
        end
    end)
end

function FeatherWeaponsClient.Equip(itemInstanceId, callback)
    FeatherCore.RPC.Call("feather-weapons:equip:request", { itemInstanceId = itemInstanceId }, function(result, rpcError)
        if not result or not result.ok then
            if callback then callback(result, rpcError) end
            return
        end

        local authorization = result.value
        pendingToken, pendingNativeWeaponName = authorization.token, authorization.nativeWeaponName

        local nativeHash = joaat(authorization.nativeWeaponName)
        ResetNativeAmmo("weapon-equipped", authorization.nativeAmmoName)
        GiveApprovedNativeWeapon(authorization.nativeWeaponName, authorization.nativeAmmoName, authorization.ammo,
            authorization.loaded, authorization.attachments)
        FeatherCore.RPC.Call("feather-weapons:equip:acknowledge", { token = authorization.token },
        function(ack, ackError)
            if not ack or not ack.ok then
                RemoveNativeWeapon(PlayerPedId(), nativeHash)
                ResetNativeAmmo("equip-rejected", authorization.nativeAmmoName)
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

function FeatherWeaponsClient.Unequip(callback)
    FeatherCore.RPC.Call("feather-weapons:equip:unequip", {}, function(result, rpcError)
        if result and result.ok then
            ClearNativeWeapon()
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
        sessionId = equipped.sessionId
    }
end

function FeatherWeaponsClient.Unload(amount, callback)
    FeatherCore.RPC.Call("feather-weapons:ammo:unload", { amount = amount }, function(result, rpcError)
        if result and result.ok and equipped then
            equipped.ammo = tonumber(result.value.total) or 0
            equipped.loaded = tonumber(result.value.loaded) or 0
            equipped.reserve = tonumber(result.value.reserve) or 0
            desiredAmmo = equipped.ammo
            desiredLoaded = equipped.loaded
            RestoreApprovedNativeWeapon(equipped.nativeWeaponName,
                result.value.nativeAmmoName or equipped.nativeAmmoName, equipped.ammo,
                equipped.loaded, equipped.attachments)
        end

        if callback then
            callback(result, rpcError)
        end
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
            equipped.loaded, equipped.attachments)
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

    local installedIds = {}
    for _, installed in ipairs(equipped.attachments or {}) do
        installedIds[installed.definitionId] = true
    end
    local weaponDefinition = WeaponDefinitionCatalog.weapons[equipped.definitionId]
    local compatibleIds = {}
    for _, attachmentIds in pairs(weaponDefinition and weaponDefinition.attachmentSlots or {}) do
        for _, attachmentId in ipairs(attachmentIds) do compatibleIds[attachmentId] = true end
    end
    for attachmentId in pairs(compatibleIds) do
        if not installedIds[attachmentId] then
            local definition = WeaponDefinitionCatalog.attachments[attachmentId]
            ModificationPage:RegisterElement("button", {
                label = ("Install %s"):format(definition and definition.label or attachmentId:gsub("_", " ")),
                slot = "content"
            }, function()
                ModificationMenu:Close()
                FeatherCore.RPC.Call("feather-weapons:attachment:install", { attachmentId = attachmentId },
                    function(result, rpcError)
                        HandleAttachmentResult(result or { ok = false, error = rpcError })
                    end)
            end)
        end
    end

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

RegisterNetEvent("feather-weapons:client:clearAuthorization",
    function(token) if pendingToken == token then ClearNativeWeapon() end end)
RegisterNetEvent("feather-weapons:client:inventoryAmmoResult", function(result)
    if result and result.ok and equipped then
        equipped.ammo = tonumber(result.value.total) or equipped.ammo
        equipped.loaded = tonumber(result.value.loaded) or equipped.loaded
        equipped.reserve = tonumber(result.value.reserve) or (equipped.ammo - equipped.loaded)
        desiredAmmo, desiredLoaded = equipped.ammo, equipped.loaded
        SetNativeAmmo(result.value.nativeAmmoName or equipped.nativeAmmoName,
            equipped.ammo, equipped.nativeWeaponName, equipped.loaded)
        Notify(("Escrowed %s cartridge%s."):format(
            tostring(result.value.moved), result.value.moved == 1 and "" or "s"))
        return
    end
    local failure = result and result.error
    Notify(failure and failure.message or "Unable to escrow ammunition.")
end)
RegisterNetEvent("feather-weapons:client:clearEquipped", ClearNativeWeapon)
RegisterNetEvent("feather-weapons:client:clearSession", ClearNativeWeapon)
RegisterNetEvent("feather-weapons:client:reconcile", function() FeatherWeaponsClient.Reconcile() end)
RegisterNetEvent("feather-weapons:client:forceReconcile", function()
    ClearNativeWeapon()
    FeatherWeaponsClient.Reconcile()
end)

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
    local runtimeConfig = Config.Runtime or {}
    local observationInterval = math.max(25,
        math.floor(tonumber(runtimeConfig.observationIntervalMs) or 50))
    local checkpointDebounce = math.max(0,
        math.floor(tonumber(runtimeConfig.checkpointDebounceMs) or 250))
    local wasDead = false
    while true do
        if equipped and desiredAmmo ~= nil then
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
                        print(("[feather-weapons] native ammo exceeded lease observed=%d approved=%d generation=%s")
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
    RegisterCharacterLogoutCheckpoint()
    FeatherWeaponsClient.Reconcile()
end)
AddEventHandler("Feather:Character:Logout", function()
    inventoryWeaponInFlight = false
    ClearNativeWeapon()
end)

RegisterCharacterLogoutCheckpoint = function()
    if GetResourceState("feather-character") ~= "started" then return end
    local called, result = pcall(function()
        return exports["feather-character"]:RegisterLogoutCheckpoint(
            "feather-weapons:runtime", "CheckpointBeforeLogout")
    end)
    if Config.DevMode then
        local passed = called and result and result.ok == true
        local failure = type(result) == "table" and (result.error or result) or nil
        print(("[feather-weapons] character logout checkpoint registration %s code=%s message=%s"):format(
            passed and "PASS" or "FAIL",
            tostring(passed and "none" or (failure and failure.code) or "export_error"),
            tostring(passed and "none" or (failure and failure.message) or result)))
    end
end

exports("CheckpointBeforeLogout", function()
    local pending = promise.new()
    FeatherWeaponsClient.Checkpoint(function(checkpoint) pending:resolve(checkpoint) end)
    local checkpoint = Citizen.Await(pending)
    if Config.DevMode then
        print(("[feather-weapons] logout checkpoint %s total=%s loaded=%s"):format(
            checkpoint and checkpoint.ok and "PASS" or "FAIL",
            tostring(checkpoint and checkpoint.value and checkpoint.value.total),
            tostring(checkpoint and checkpoint.value and checkpoint.value.loaded)))
    end
    return checkpoint
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RegisterCharacterLogoutCheckpoint()
        FeatherWeaponsClient.Reconcile()
    elseif resourceName == "feather-character" then
        RegisterCharacterLogoutCheckpoint()
    end
end)
AddEventHandler("onResourceStop",
    function(resourceName) if resourceName == GetCurrentResourceName() then ClearNativeWeapon() end end)

if Config.DevMode then
    RegisterCommand("weaponstate", function()
        FeatherWeaponsClient.Reconcile(function(result, rpcError)
            if result and result.ok then
                local state = result.value.equipped
                print(("[feather-weapons] state equipped=%s item=%s generation=%s total=%s loaded=%s reserve=%s condition=%s")
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
                    print(("[feather-weapons] attachments count=%s ids=%s"):format(
                        tostring(#attachmentIds), #attachmentIds > 0 and table.concat(attachmentIds, ",") or "none"))
                    local ped = PlayerPedId()
                    local clipOk, nativeLoaded = GetAmmoInClip(ped, joaat(state.nativeWeaponName))
                    local nativeTotal = GetPedAmmoByType(ped, joaat(state.nativeAmmoName))
                    print(("[feather-weapons] native total=%s loaded=%s clipOk=%s"):format(
                        tostring(nativeTotal), tostring(nativeLoaded), tostring(clipOk)))
                end
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
