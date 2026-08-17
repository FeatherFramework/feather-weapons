-- (WPN-07) Raw RegisterServerEvent, not on the Feather:Call RPC bus, so it
-- doesn't inherit Phase 2's CORE-06 rate limiter. Legitimate flow only
-- fires this once per spawn (Feather:Character:Spawned), so a short
-- cooldown is safe and bounds spam.
local lastInitAt = {}
local INIT_COOLDOWN_MS = 3000

AddEventHandler('playerDropped', function()
    lastInitAt[source] = nil
end)

-- (WPN-02) `charId` was trusted directly from the client -- any client
-- could seed/read another character's ammo row by id. Re-derived from
-- source instead, same ownership pattern established in Phase 2.
RegisterServerEvent("feather-weapons:Init", function(charId)
    local _source = source

    local now = GetGameTimer()
    if lastInitAt[_source] and (now - lastInitAt[_source]) < INIT_COOLDOWN_MS then
        return
    end
    lastInitAt[_source] = now

    local player = FeatherCore.Character.GetCharacter({ src = _source })
    local character = player and player.char
    if not character then
        return
    end

    -- ensure the player has a row in the ammo table
    local ammo = MySQL.query.await("SELECT * FROM ammo WHERE char_id = ?", { character.id })
    if #ammo <= 0 then
        -- Creating new row if player doesn't have one
        MySQL.query.await("INSERT INTO ammo (char_id) VALUES (?)", { character.id })
    else
        -- Sending ammo to client if player has a row
        for k, v in pairs(AmmoTypes) do
            if ammo[1][string.lower(k)] > 0 then
                TriggerClientEvent("feather-weapons:AddAmmo", _source, k, ammo[1][string.lower(k)])
            end
        end
    end
end)