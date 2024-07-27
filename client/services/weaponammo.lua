-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
RegisterNetEvent("feather-weapons:AddAmmo", function(ammoType, amount)
    Citizen.InvokeNative(0x5FD1E1F011E76D7E, PlayerPedId(), joaat(ammoType), amount, 0xCA3454E6)
end)