-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
AmmoAPI = {}

function AmmoAPI.AddAmmo(ammoType, amount, src)
    ammoType = string.upper(ammoType) -- Ensure the ammo type is in uppercase to match the game's ammo types
    if type(ammoType) == "string" and type(amount) == "number" and type (src) == "number" then
        for k, v in pairs(AmmoTypes) do
            if k == ammoType then
                local player = FeatherCore.Character.GetCharacter({ src = src })
                local currentAmmo = MySQL.query.await("SELECT ? WHERE char_id = ?", { string.lower(ammoType), player.char.id })
                if tonumber(currentAmmo[1]) >= v.max then
                    print("FeatherWeapons.AmmoAPI.AddAmmo: Player already has max ammo for this type.") break
                else
                    if tonumber(currentAmmo[1]) + amount <= v.max then
                        MySQL.query.await("UPDATE ammo SET ? = ? WHERE char_id = ?", { string.lower(ammoType), tonumber(currentAmmo[1]) + amount, player.char.id })
                        TriggerClientEvent("feather-weapons:AddAmmo", src, ammoType, amount) break
                    else
                        MySQL.query.await("UPDATE ammo SET ? = ? WHERE char_id = ?", { string.lower(ammoType), v.max, player.char.id })
                        TriggerClientEvent("feather-weapons:AddAmmo", src, ammoType, v.max - tonumber(currentAmmo[1])) break -- adding max ammo
                    end
                end
            end
        end
    else
        print("FeatherWeapons.AmmoAPI.AddAmmo: Invalid parameters passed.")
    end
end