-- TODO Add check to see if player already has a weapon in the same slot equipped

RegisterNetEvent("feather-weapons:equipWeapon", function(weaponName)
    if WeaponList[weaponName] then
        local wepHash = joaat(weaponName)
        GiveWeaponToPed(PlayerPedId(), wepHash, 0, true, true, 3, false, 0.5, 1.0, 752097756, false, 0, false)
    end
end)