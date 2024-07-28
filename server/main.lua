RegisterServerEvent('giveTestWeapon', function()
    local _source = source
    FeatherInv.Items.AddItem('volcanic_pistol', 1, nil, _source)
    FeatherInv.Items.AddItem('doubleaction_revolver', 1, nil, _source)
    FeatherInv.Items.AddItem('sawedoff_shotgun', 1, nil, _source)
    FeatherInv.Items.AddItem('evans_repeater', 1, nil, _source)
    FeatherInv.Items.AddItem('springfield_rifle', 1, nil, _source)
    FeatherInv.Items.AddItem('pump_shotgun', 1, nil, _source)
    FeatherInv.Items.AddItem('carcano_sniper', 1, nil, _source)
    FeatherInv.Items.AddItem('bow', 1, nil, _source)
    FeatherInv.Items.AddItem('bow', 1, nil, _source)
end)

RegisterServerEvent("feather-weapons:Init", function(charId)
    local _source = source
    -- ensure the player has a row in the ammo table
    local ammo = MySQL.query.await("SELECT * FROM ammo WHERE char_id = ?", { charId })
    if #ammo <= 0 then
        -- Creating new row if player doesn't have one
        MySQL.query.await("INSERT INTO ammo (char_id) VALUES (?)", { charId })
    else
        -- Sending ammo to client if player has a row
        for k, v in pairs(AmmoTypes) do
            if ammo[1][string.lower(k)] > 0 then
                TriggerClientEvent("feather-weapons:AddAmmo", _source, k, ammo[1][string.lower(k)])
            end
        end
    end
end)