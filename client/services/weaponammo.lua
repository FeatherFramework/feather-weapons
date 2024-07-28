-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
RegisterNetEvent("feather-weapons:AddAmmo", function(ammoType, amount)
    Citizen.InvokeNative(0x5FD1E1F011E76D7E, PlayerPedId(), joaat(ammoType), amount, 0xCA3454E6)
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