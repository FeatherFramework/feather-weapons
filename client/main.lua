AmmoCache, CharSpawned = nil , false

RegisterNetEvent("Feather:Character:Spawned", function(character)
    TriggerServerEvent("feather-weapons:Init", character.id)
    FeatherCore.RPC.Call('feather-weapons:GetAmmo', { charId = character.id }, function(result)
        if result then
            AmmoCache = result
        end
    end)
    CharSpawned = true
end)