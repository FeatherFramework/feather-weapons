RegisterNetEvent("Feather:Character:Spawned", function(character)
    TriggerServerEvent("feather-weapons:Init", character.id)
end)