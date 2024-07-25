RegisterServerEvent('giveTestWeapon', function()
    local _source = source
    FeatherInv.Items.AddItem('volcanic_pistol', 1, nil, _source)
    Wait(100)
    FeatherInv.Items.AddItem('knife', 1, nil, _source)
end)