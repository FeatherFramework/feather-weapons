local equippedWeapons = nil

RegisterNetEvent("feather-weapons:equipWeapon", function(weaponName)
    local weaponFound = false
    for k, v in pairs(WeaponList) do
        if weaponName == v.weaponName then
            weaponFound = true break
        end
    end
    if weaponFound then
        local wepHash = joaat(weaponName)
        GiveWeaponToPed(PlayerPedId(), wepHash, 0, true, true, 3, false, 0.5, 1.0, 752097756, false, 0, false)
    end
end)