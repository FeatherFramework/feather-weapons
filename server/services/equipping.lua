-- Weapon Registering
CreateThread(function()
    for k, v in pairs(WeaponList) do
        FeatherInv.Items.RegisterUsableItem(v.weaponDBName, function(item, src, updateCB)
            TriggerClientEvent("feather-weapons:equipWeapon", src, k, item.id)
        end)
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