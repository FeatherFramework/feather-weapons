local weaponSlots = {["pistol"] = nil, ["longgun"] = nil, ["secondaryLonggun"] = nil, ["melee"] = nil, ["throwable"] = nil} -- This will store what weapon slots have weapons equipped so we can check if the player already has a weapon equipped in that slot

-- (WPN-04) The network-reachable half of this finding is already closed:
-- the only server-driven trigger is feather-inventory's usable-item
-- callback (server/services/equipping.lua), which since Phase 2's INV-02
-- fix only fires for an item the caller actually, verifiably owns -- an
-- executor can no longer reach this cross-player or via a spoofed item id.
-- What remains is a same-client local TriggerEvent self-trigger, which is
-- not fixable at this layer: RegisterNetEvent handlers can always be fired
-- locally by their own client, and a cheat client could call
-- GiveWeaponToPed directly via the raw native regardless of whether this
-- handler exists at all -- this is RedM's client-authoritative weapon
-- state, the same limitation the Phase 1 audit already concluded. No
-- server-side consequence currently depends on equip state (ammo
-- consumption is tracked/reconciled server-side per WPN-01, not equip
-- state), so there is no privileged action left for this residual gap to
-- unlock.
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