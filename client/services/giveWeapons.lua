local function GivePedWeapon(ped, weaponHash, ammoCount, forceInHand)
    GiveWeaponToPed_2(ped, weaponHash, ammoCount, forceInHand, false, 0, true, 0.5, 1.0, 0x2CD419DC, true, 0,0)
end

RegisterCommand("giveWeapon", function()
    GivePedWeapon(PlayerPedId(), joaat("weapon_melee_machete"), 100, true)
end)