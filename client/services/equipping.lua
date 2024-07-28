local weaponSlots = {["pistol"] = nil, ["longgun"] = nil, ["secondaryLonggun"] = nil, ["melee"] = nil, ["throwable"] = nil} -- This will store what weapon slots have weapons equipped so we can check if the player already has a weapon equipped in that slot

RegisterNetEvent("feather-weapons:equipWeapon", function(weaponName, itemId)
    if WeaponList[weaponName] then
        local weaponSlot = WeaponList[weaponName].weaponSlot
        local function equipWeaponToPed(wepSlot)
            local wepHash = joaat(weaponName)
            GiveWeaponToPed(PlayerPedId(), wepHash, 0, false, true)
            weaponSlots[wepSlot] = { itemId = itemId, weaponName = weaponName }
        end
        if weaponSlot ~= "longgun" and weaponSlot ~= "secondaryLonggun" then
            if not weaponSlots[weaponSlot] then
                equipWeaponToPed(weaponSlot)
            else
                TriggerEvent("feather-weapons:unequipWeapon", weaponSlots[weaponSlot].itemId)
            end
        elseif weaponSlot == "longgun" or weaponSlot == "secondaryLonggun" then -- specific name check to ensure we pass the proper slot
            if not weaponSlots['longgun'] then
                equipWeaponToPed('longgun')
            elseif not weaponSlots['secondaryLonggun'] then
                equipWeaponToPed('secondaryLonggun')
            elseif weaponSlots['longgun'] then
                TriggerEvent("feather-weapons:unequipWeapon", weaponSlots['longgun'].itemId)
            elseif weaponSlots['secondaryLonggun'] then
                TriggerEvent("feather-weapons:unequipWeapon", weaponSlots['secondaryLonggun'].itemId)
            end
        end
    end
end)

RegisterNetEvent("feather-weapons:unequipWeapon", function(itemId)
    if weaponSlots["pistol"] then
        if weaponSlots["pistol"].itemId == itemId then
            RemoveWeaponFromPed(PlayerPedId(), joaat(weaponSlots['pistol'].weaponName))
            weaponSlots["pistol"] = nil
        end
    end
    if weaponSlots["longgun"] then
        if weaponSlots["longgun"].itemId == itemId then
            RemoveWeaponFromPed(PlayerPedId(), joaat(weaponSlots['longgun'].weaponName))
            weaponSlots["longgun"] = nil
        end
    end
    if weaponSlots["secondaryLonggun"] then
        if weaponSlots["secondaryLonggun"].itemId == itemId then
            RemoveWeaponFromPed(PlayerPedId(), joaat(weaponSlots['secondaryLonggun'].weaponName))
            weaponSlots["secondaryLonggun"] = nil
        end
    end
    if weaponSlots["melee"] then
        if weaponSlots["melee"].itemId == itemId then
            RemoveWeaponFromPed(PlayerPedId(), joaat(weaponSlots['melee'].weaponName))
            weaponSlots["melee"] = nil
        end
    end
    if weaponSlots["throwable"] then
        if weaponSlots["throwable"].itemId == itemId then
            RemoveWeaponFromPed(PlayerPedId(), joaat(weaponSlots['throwable'].weaponName))
            weaponSlots["throwable"] = nil
        end
    end
end)