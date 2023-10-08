GiveWeaponsAPI = {}

function GiveWeaponsAPI:GivePedWeapon(ped, weaponName, ammoCount, forceInHand)
    --The following inHolster catch is necessary as if u do not force the weapon in hand and leave forceinholster false it will not show up in the players(if the ped is a player) weapon wheel
    local inHolster = false
    if not forceInHand then
        inHolster = true
    end
    --Giving the ped the weapon
    GiveWeaponToPed_2(ped, joaat(weaponName), ammoCount, forceInHand, inHolster, 0, true, 0.5, 1.0, 0x2CD419DC, true, 0,0)
end

--[[
    Notes all group hashes can get with GetWeapontypeGroup native
    pistol  hash = 416676503
    melee hash = -728555052
    repeater hash = -594562071
    revolver hash = -1101297303
    rifle hash = 970310034
    shotgun hash = 860033945
    sniper hash = -1212426201
    thrown hash = 1548507267
    held hash = -954861255
    bow hash = -1241684019
    fishingrod hash = 1622482340
    lasso hash = 308416707
]]