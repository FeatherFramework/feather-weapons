-- Dev/test-only ammo grant, mirroring feather-inventory's Config.DevMode +
-- ACE-restricted dev command pattern (server/services/commands.lua there).
-- feather-inventory's own /AddItems already covers granting the weapon item
-- itself -- ammo is tracked entirely separately (this resource's own `ammo`
-- table, AmmoAPI.AddAmmo/SubtractAmmo in weaponammo.lua), so it needs its
-- own command.
if Config.DevMode then
    RegisterCommand('AddAmmo', function(source, args)
        local ok = AmmoAPI.AddAmmo(args[1], tonumber(args[2]), source)
        FeatherCore.Notify.ToolTip(source, ok and "Ammo added!" or "Failed to add ammo (check ammo type/amount)", 3000)
    end, true)
end
