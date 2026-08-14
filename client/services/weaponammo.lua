-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
-- (WPN-06) This event is self-triggerable by a local executor (RegisterNetEvent
-- + local TriggerEvent never leaves the client), which is an inherent
-- RedM client-authoritative-state limitation no server-side script change
-- can prevent -- a cheat client could call the ammo-setting native
-- directly regardless of whether this handler exists. What WAS fixable:
-- this handler never updated the AmmoCache mirror used by UpdateAmmo's
-- periodic flush, so legitimately server-granted ammo (Init, AmmoAPI.AddAmmo)
-- would look stale on the next flush and get misread as "consumption" by
-- the server's now-authoritative subtract-only reconciliation (WPN-01).
-- Keeping AmmoCache in sync here also means a self-triggered fraudulent
-- call can inflate the local mirror but can never get persisted to the DB,
-- since the server only ever accepts decreases relative to its own record.
RegisterNetEvent("feather-weapons:AddAmmo", function(ammoType, amount)
    Citizen.InvokeNative(0x5FD1E1F011E76D7E, PlayerPedId(), joaat(ammoType), amount, 0xCA3454E6)

    if AmmoCache then
        local column = string.lower(ammoType)
        AmmoCache[column] = (AmmoCache[column] or 0) + amount
    end
end)

-- Monitoring shooting to remove ammo
CreateThread(function()
    while true do
        Wait(5)
        if CharSpawned then
            if IsPedShooting(PlayerPedId()) then
                local bool, weaponHash = GetCurrentPedWeapon(PlayerPedId())
                if bool then
                    local ammoHash = GetCurrentPedWeaponAmmoType(PlayerPedId(), GetPedWeaponObject(PlayerPedId(), true))
                    for k, v in pairs(AmmoTypes) do
                        if ammoHash == v.ammoHash then
                            AmmoCache[string.lower(k)] = AmmoCache[string.lower(k)] - 1
                        end
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(30000) -- Save ammo every 30 seconds
        if CharSpawned then
            TriggerServerEvent("feather-weapons:UpdateAmmo", AmmoCache)
        end
    end
end)