-- This file is named weaponamma.lua and not ammo.lua to ensure it loads after api (so we dont have to make special loads in fxmanifest)
AmmoAPI = {}

-- (WPN-05) SELECT ?/UPDATE ... SET ? = ? previously bound the ammo column
-- NAME as a query parameter -- oxmysql binds parameters as values, not
-- identifiers, so these queries read/wrote the literal string instead of
-- touching the real column, and `tonumber(currentAmmo[1])` on that literal
-- was always nil, breaking the `>= v.max` comparison. That's why this
-- "capped" path never actually worked, and the unchecked WPN-01 direct
-- write was the only one that did. The column name is now safely
-- interpolated -- safe because it is only ever derived from a successful
-- lookup against AmmoTypes (a fixed, code-defined table), never from
-- ammoType directly, so a caller can't smuggle an arbitrary identifier in
-- even if ammoType ultimately originates from client input upstream (as it
-- will once WPN-01's fix routes through here).
function AmmoAPI.AddAmmo(ammoType, amount, src)
    if type(ammoType) ~= "string" or type(amount) ~= "number" or type(src) ~= "number" then
        print("FeatherWeapons.AmmoAPI.AddAmmo: Invalid parameters passed.")
        return false
    end

    ammoType = string.upper(ammoType)
    local ammoDef = AmmoTypes[ammoType]
    if not ammoDef then
        print("FeatherWeapons.AmmoAPI.AddAmmo: Unknown ammo type: " .. ammoType)
        return false
    end

    if amount <= 0 then
        print("FeatherWeapons.AmmoAPI.AddAmmo: amount must be positive.")
        return false
    end

    local player = FeatherCore.Character.GetCharacter({ src = src })
    local character = player and player.char
    if not character then
        print("FeatherWeapons.AmmoAPI.AddAmmo: No character loaded for src: " .. src)
        return false
    end

    local column = string.lower(ammoType) -- safe: ammoType is a validated AmmoTypes key, not raw input
    local row = MySQL.query.await("SELECT `" .. column .. "` FROM ammo WHERE char_id = ?", { character.id })
    if not row or not row[1] then
        print("FeatherWeapons.AmmoAPI.AddAmmo: No ammo row for char_id: " .. character.id)
        return false
    end

    local currentAmmo = tonumber(row[1][column]) or 0
    if currentAmmo >= ammoDef.max then
        return false
    end

    local newAmmo = math.min(currentAmmo + amount, ammoDef.max)
    MySQL.query.await("UPDATE ammo SET `" .. column .. "` = ? WHERE char_id = ?", { newAmmo, character.id })
    TriggerClientEvent("feather-weapons:AddAmmo", src, ammoType, newAmmo - currentAmmo)
    return true
end

-- Symmetric to AddAmmo -- the sanctioned way to reduce a character's ammo
-- (e.g. WPN-01's consumption sync below). Clamped to never go below 0.
-- Same identifier-safety reasoning as AddAmmo: column comes only from a
-- validated AmmoTypes lookup.
function AmmoAPI.SubtractAmmo(ammoType, amount, src)
    if type(ammoType) ~= "string" or type(amount) ~= "number" or type(src) ~= "number" then
        print("FeatherWeapons.AmmoAPI.SubtractAmmo: Invalid parameters passed.")
        return false
    end

    ammoType = string.upper(ammoType)
    if not AmmoTypes[ammoType] then
        print("FeatherWeapons.AmmoAPI.SubtractAmmo: Unknown ammo type: " .. ammoType)
        return false
    end

    if amount <= 0 then
        return false
    end

    local player = FeatherCore.Character.GetCharacter({ src = src })
    local character = player and player.char
    if not character then
        print("FeatherWeapons.AmmoAPI.SubtractAmmo: No character loaded for src: " .. src)
        return false
    end

    local column = string.lower(ammoType)
    local row = MySQL.query.await("SELECT `" .. column .. "` FROM ammo WHERE char_id = ?", { character.id })
    if not row or not row[1] then
        return false
    end

    local currentAmmo = tonumber(row[1][column]) or 0
    local newAmmo = math.max(currentAmmo - amount, 0)
    MySQL.query.await("UPDATE ammo SET `" .. column .. "` = ? WHERE char_id = ?", { newAmmo, character.id })
    return true
end

-- (WPN-02) params.charId was trusted directly from the client -- any client
-- could read any character's full ammo row by id. Re-derived from src
-- instead, same ownership pattern established in Phase 2 (feather-core's
-- GetCharacter({src=...})). This already inherits Phase 2's CORE-06 RPC
-- rate limiter since it's registered on the shared Feather:Call bus.
FeatherCore.RPC.Register("feather-weapons:GetAmmo", function(params, cb, src)
    local player = FeatherCore.Character.GetCharacter({ src = src })
    local character = player and player.char
    if not character then
        return cb(false)
    end

    local ammo = MySQL.query.await("SELECT * FROM ammo WHERE char_id = ?", { character.id })
    if #ammo > 0 then
        cb(ammo[1])
    else
        cb(false)
    end
end)

-- (WPN-07) Init/UpdateAmmo are raw RegisterServerEvents, not RPCs on the
-- Feather:Call bus, so they don't inherit Phase 2's CORE-06 rate limiter.
-- Lightweight per-source cooldowns here close that gap without needing to
-- migrate these to the RPC bus.
local lastUpdateAmmoAt = {}
local UPDATE_AMMO_COOLDOWN_MS = 5000 -- client only flushes every 30s legitimately

AddEventHandler('playerDropped', function()
    lastUpdateAmmoAt[source] = nil
end)

-- (WPN-01) Previously wrote the client's full ammo table verbatim -- no
-- cap, no validation -- so an executor could self-grant unlimited ammo of
-- any type (including explosive rounds) just by sending a crafted table.
-- This handler is the client's periodic "flush what I've fired" sync
-- (client/services/weaponammo.lua decrements AmmoCache locally as the
-- player shoots, then flushes it here every 30s); its only legitimate
-- effect is ammo going DOWN. Every ammo type is now compared against the
-- server's own authoritative row and, if genuinely lower, routed through
-- AmmoAPI.SubtractAmmo -- itself clamped to never go below 0. Any type the
-- client reports as unchanged or increased is simply ignored rather than
-- trusted; increases can only happen through AmmoAPI.AddAmmo's capped path.
RegisterServerEvent("feather-weapons:UpdateAmmo", function(ammo)
    local _source = source

    local now = GetGameTimer()
    if lastUpdateAmmoAt[_source] and (now - lastUpdateAmmoAt[_source]) < UPDATE_AMMO_COOLDOWN_MS then
        return
    end
    lastUpdateAmmoAt[_source] = now

    if type(ammo) ~= "table" then
        return
    end

    local player = FeatherCore.Character.GetCharacter({ src = _source })
    local character = player and player.char
    if not character then
        return
    end

    local row = MySQL.query.await("SELECT * FROM ammo WHERE char_id = ?", { character.id })
    local currentRow = row and row[1]
    if not currentRow then
        return
    end

    for ammoType, def in pairs(AmmoTypes) do
        local column = string.lower(ammoType)
        local reported = tonumber(ammo[column])
        local current = tonumber(currentRow[column]) or 0

        if reported ~= nil and reported < current then
            AmmoAPI.SubtractAmmo(ammoType, current - reported, _source)
        end
    end
end)