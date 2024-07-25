RegisterCommand("giveTestWeapon", function()
    TriggerServerEvent("giveTestWeapon")
    AmmoAPI.AddAmmo("AMMO_PISTOL", 100)
end)