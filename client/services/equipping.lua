local weaponSlots = {["pistol"] = false, ["longgun"] = false, ["secondaryLonggun"] = false, ["melee"] = false, ["throwable"] = false} -- This will store what weapon slots have weapons equipped so we can check if the player already has a weapon equipped in that slot

RegisterNetEvent("feather-weapons:equipWeapon", function(weaponName)
    if WeaponList[weaponName] then
        local weaponSlot = weaponSlots[WeaponList[weaponName].weaponSlot]
        local function equipWeaponToPed(wepSlot)
            local wepHash = joaat(weaponName)
            GiveWeaponToPed(PlayerPedId(), wepHash, 0, true, true, 3, false, 0.5, 1.0, 752097756, false, 0, false)
            weaponSlots[wepSlot] = true
        end
        if weaponSlot ~= "longgun" or weaponSlot ~= "secondaryLonggun" then
            if not weaponSlots[weaponSlot] then
                equipWeaponToPed(weaponSlot)
            end
        elseif weaponSlot == "longgun" or weaponSlot == "secondaryLonggun" then -- specific name check to prevent incorrect weapon names from being equipped
            if not weaponSlots['longgun'] then
                equipWeaponToPed('longgun')
            elseif not weaponSlots['secondaryLonggun'] then
                equipWeaponToPed('secondaryLonggun')
            end
        end
    end
end)