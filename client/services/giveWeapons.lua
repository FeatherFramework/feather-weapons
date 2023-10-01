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