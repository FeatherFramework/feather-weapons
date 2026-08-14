-- AmmoCache is this client's local mirror of its ammo row, kept in sync
-- with the server (see client/services/weaponammo.lua) and periodically
-- flushed back up as consumption deltas. CharSpawned gates the shooting-
-- watch and flush loops (client/services/weaponammo.lua) so they don't run
-- before a character/ammo row actually exists.
AmmoCache, CharSpawned = nil , false

-- Bootstraps this resource's per-character state on spawn: ensures the
-- server has an ammo row for this character (Init) and pulls it down into
-- AmmoCache (GetAmmo).
RegisterNetEvent("Feather:Character:Spawned", function(character)
    TriggerServerEvent("feather-weapons:Init", character.id)
    FeatherCore.RPC.Call('feather-weapons:GetAmmo', { charId = character.id }, function(result)
        if result then
            AmmoCache = result
        end
    end)
    CharSpawned = true
end)