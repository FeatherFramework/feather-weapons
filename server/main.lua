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