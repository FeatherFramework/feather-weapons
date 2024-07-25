-- Weapon Registering
CreateThread(function()
    for k, v in pairs(Config.weapons) do
        FeatherInv.Items.RegisterUsableItem(v.weaponDBName, function(item, src, updateCB)
            TriggerClientEvent("feather-weapons:equipWeapon", src, v.weaponHash, item.id)
        end)
    end
end)

RegisterServerEvent('feather-inventory:ItemRemoved', function(itemId, quantity, invId)
    TriggerClientEvent("feather-weapons:unequipWeapon", -1, itemId) -- -1 to send to all players as this event doesnt have a player source param for us to use
end)