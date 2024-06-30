-- Weapon Registering
CreateThread(function()
    for k, v in pairs(Config.weapons) do
        FeatherInv.Items.RegisterUsableItem(v.weaponDBName, function(item)
            print("IT WAS USED")
        end)
    end
end)