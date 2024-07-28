-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
AmmoAPI = {}

function AmmoAPI.AddAmmo(ammoType, amount, src)
    if type(ammoType) == "string" and type(amount) == "number" and type (src) == "number" then
        ammoType = string.upper(ammoType) -- Ensure the ammo type is in uppercase to match the game's ammo types
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

FeatherCore.RPC.Register("feather-weapons:GetAmmo", function(params, cb, src)
    local ammo = MySQL.query.await("SELECT * FROM ammo WHERE char_id = ?", { params.charId })
    if #ammo > 0 then
        cb(ammo[1])
    else
        cb(false)
    end
end)

RegisterServerEvent("feather-weapons:UpdateAmmo", function(ammo)
    local _source = source
    local player = FeatherCore.Character.GetCharacter({ src = _source })
    MySQL.query.await("UPDATE ammo SET ammo_22 = ?, ammo_22_tranquilizer = ?, ammo_arrow = ?, ammo_arrow_confusion = ?, ammo_arrow_disorient = ?, ammo_arrow_drain = ?, ammo_arrow_dynamite = ?, ammo_arrow_fire = ?, ammo_arrow_improved = ?, ammo_arrow_poison = ?, ammo_arrow_small_game = ?, ammo_arrow_tracking = ?, ammo_arrow_trail = ?, ammo_arrow_wound = ?, ammo_bolas = ?, ammo_bolas_hawkmoth = ?, ammo_bolas_intertwined = ?, ammo_bolas_ironspiked = ?, ammo_cannon = ?, ammo_dynamite = ?, ammo_dynamite_volatile = ?, ammo_hatchet = ?, ammo_hatchet_ancient = ?, ammo_hatchet_cleaver = ?, ammo_hatchet_double_bit = ?, ammo_hatchet_double_bit_rusted = ?, ammo_hatchet_hewing = ?, ammo_hatchet_hunter = ?, ammo_hatchet_hunter_rusted = ?, ammo_hatchet_viking = ?, ammo_lasso = ?, ammo_lasso_reinforced = ?, ammo_molotov = ?, ammo_molotov_volatile = ?, ammo_moonshinejug = ?, ammo_moonshinejug_mp = ?, ammo_pistol = ?, ammo_pistol_express = ?, ammo_pistol_express_explosive = ?, ammo_pistol_high_velocity = ?, ammo_pistol_split_point = ?, ammo_poisonbottle = ?, ammo_repeater = ?, ammo_repeater_express = ?, ammo_repeater_express_explosive = ?, ammo_repeater_high_velocity = ?, ammo_repeater_split_point = ?, ammo_revolver = ?, ammo_revolver_express = ?, ammo_revolver_express_explosive = ?, ammo_revolver_high_velocity = ?, ammo_revolver_split_point = ?, ammo_rifle = ?, ammo_rifle_elephant = ?, ammo_rifle_express = ?, ammo_rifle_express_explosive = ?, ammo_rifle_high_velocity = ?, ammo_rifle_split_point = ?, ammo_shotgun = ?, ammo_shotgun_buckshot_incendiary = ?, ammo_shotgun_slug = ?, ammo_shotgun_slug_explosive = ?, ammo_throwing_knives = ?, ammo_throwing_knives_confuse = ?, ammo_throwing_knives_disorient = ?, ammo_throwing_knives_drain = ?, ammo_throwing_knives_improved = ?, ammo_throwing_knives_javier = ?, ammo_throwing_knives_poison = ?, ammo_throwing_knives_trail = ?, ammo_throwing_knives_wound = ?, ammo_thrown_item = ?, ammo_tomahawk = ?, ammo_tomahawk_ancient = ?, ammo_tomahawk_homing = ?, ammo_tomahawk_improved = ?, ammo_turret = ? WHERE char_id = ?", { ammo.ammo_22, ammo.ammo_22_tranquilizer, ammo.ammo_arrow, ammo.ammo_arrow_confusion, ammo.ammo_arrow_disorient, ammo.ammo_arrow_drain, ammo.ammo_arrow_dynamite, ammo.ammo_arrow_fire, ammo.ammo_arrow_improved, ammo.ammo_arrow_poison, ammo.ammo_arrow_small_game, ammo.ammo_arrow_tracking, ammo.ammo_arrow_trail, ammo.ammo_arrow_wound, ammo.ammo_bolas, ammo.ammo_bolas_hawkmoth, ammo.ammo_bolas_intertwined, ammo.ammo_bolas_ironspiked, ammo.ammo_cannon, ammo.ammo_dynamite, ammo.ammo_dynamite_volatile, ammo.ammo_hatchet, ammo.ammo_hatchet_ancient, ammo.ammo_hatchet_cleaver, ammo.ammo_hatchet_double_bit, ammo.ammo_hatchet_double_bit_rusted, ammo.ammo_hatchet_hewing, ammo.ammo_hatchet_hunter, ammo.ammo_hatchet_hunter_rusted, ammo.ammo_hatchet_viking, ammo.ammo_lasso, ammo.ammo_lasso_reinforced, ammo.ammo_molotov, ammo.ammo_molotov_volatile, ammo.ammo_moonshinejug, ammo.ammo_moonshinejug_mp, ammo.ammo_pistol, ammo.ammo_pistol_express, ammo.ammo_pistol_express_explosive, ammo.ammo_pistol_high_velocity, ammo.ammo_pistol_split_point, ammo.ammo_poisonbottle, ammo.ammo_repeater, ammo.ammo_repeater_express, ammo.ammo_repeater_express_explosive, ammo.ammo_repeater_high_velocity, ammo.ammo_repeater_split_point, ammo.ammo_revolver, ammo.ammo_revolver_express, ammo.ammo_revolver_express_explosive, ammo.ammo_revolver_high_velocity, ammo.ammo_revolver_split_point, ammo.ammo_rifle, ammo.ammo_rifle_elephant, ammo.ammo_rifle_express, ammo.ammo_rifle_express_explosive, ammo.ammo_rifle_high_velocity, ammo.ammo_rifle_split_point, ammo.ammo_shotgun, ammo.ammo_shotgun_buckshot_incendiary, ammo.ammo_shotgun_slug, ammo.ammo_shotgun_slug_explosive, ammo.ammo_throwing_knives, ammo.ammo_throwing_knives_confuse, ammo.ammo_throwing_knives_disorient, ammo.ammo_throwing_knives_drain, ammo.ammo_throwing_knives_improved, ammo.ammo_throwing_knives_javier, ammo.ammo_throwing_knives_poison, ammo.ammo_throwing_knives_trail, ammo.ammo_throwing_knives_wound, ammo.ammo_thrown_item, ammo.ammo_tomahawk, ammo.ammo_tomahawk_ancient, ammo.ammo_tomahawk_homing, ammo.ammo_tomahawk_improved, ammo.ammo_turret, player.char.id })
end)