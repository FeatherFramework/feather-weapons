if GetCurrentResourceName() ~= "feather-weapons" then
    error("ERROR feather-weapons failed to load if you are a player report this to the server owner, if you are the server owner Feather Weapons resource must be named feather-weapons")
else
    --start core
end

CreateThread(function()
    FeatherInventory.RegisterInventory('stables', 6)
    FeatherInventory.AddItem('doubleactionrevolver', 6, nil)
    FeatherInventory.RegisterUsableItem('doubleactionrevolver', function (item)
        print('You ate an apple!')
        print(item)
    end)
end)