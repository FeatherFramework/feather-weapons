-- (Tier 1 audit sweep) Config.blacklistedWeapons was declared but never read
-- anywhere in this repo -- every weapon in WeaponList got a usable-item
-- callback registered regardless of the blacklist, so it silently did
-- nothing. Skipping registration for blacklisted weapons means the item can
-- never be equipped through this path even if a character somehow holds it.
local blacklistedWeapons = {}
for _, entry in pairs(Config.blacklistedWeapons or {}) do
    if entry.weaponName then
        blacklistedWeapons[entry.weaponName] = true
    end
end

-- Weapon Registering
CreateThread(function()
    for k, v in pairs(WeaponList) do
        if not blacklistedWeapons[k] then
            FeatherInv.Items.RegisterUsableItem(v.weaponDBName, function(item, src, updateCB)
                TriggerClientEvent("feather-weapons:equipWeapon", src, k, item.id)
            end)
        end
    end
end)

-- (WPN-03, narrow Phase 2 touch) Was RegisterServerEvent, which makes the
-- event name network-reachable -- any client could call
-- TriggerServerEvent('feather-inventory:ItemRemoved', anyItemId) directly
-- and force-unequip any player's weapon. feather-inventory only ever
-- signals this internally via TriggerEvent (see feather-inventory's Phase 2
-- audit note), so switching to AddEventHandler still catches that internal
-- signal but stops responding to client-triggered network events.
AddEventHandler('feather-inventory:ItemRemoved', function(itemId, quantity, invId)
    TriggerClientEvent("feather-weapons:unequipWeapon", -1, itemId) -- -1 to send to all players as this event doesnt have a player source param for us to use
end)