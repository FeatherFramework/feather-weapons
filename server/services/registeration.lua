-- Weapon Registering
CreateThread(function()
    for k, v in pairs(Config.weapons) do
        FeatherInv.Items.RegisterUsableItem(v.weaponDBName, function(item, src, updateCB)
            TriggerClientEvent("feather-weapons:equipWeapon", src, v.weaponHash)
        end)
    end
end)