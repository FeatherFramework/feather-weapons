# feather-weapons
> The main weapon system for Feather Framework!

# Requirments
- feather-core

# API
### To Initialize the weapon api
- This must be called before any other API's can be used
```lua
FeatherWeapons = exports['feather-weapons'].initiate()
```

### To give a weapon to a ped
```lua
    FeatherWeapons.GiveWeapons:GivePedWeapon(ped, weaponName, ammoCount, forceInHand)
```