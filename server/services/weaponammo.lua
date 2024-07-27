-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
AmmoAPI = {}

function AmmoAPI.AddAmmo(ammoType, amount, src)
    ammoType = string.upper(ammoType) -- Ensure the ammo type is in uppercase to match the game's ammo types
    if type(ammoType) == "string" and type(amount) == "number" and type (src) == "number" then
        for k, v in pairs(AmmoTypes) do
            if v == ammoType then
                local player = FeatherCore.Character.GetCharacter({ src = src })
                local currentAmmo = MySQL.query.await("SELECT ? WHERE char_id = ?", { string.lower(ammoType), player.char.id })
                print(currentAmmo)
                TriggerClientEvent("feather-weapons:AddAmmo", src, ammoType, amount) break
            end
        end
    else
        print("AmmoAPI.AddAmmo: Invalid parameters passed.")
    end
end

-- pistol max ammo 100
-- revolver max ammo 200
-- shotgun max ammo 60
-- repeater max ammo 200
-- rifle max ammo 100
-- sniper max ammo 100
-- bow max ammo 40