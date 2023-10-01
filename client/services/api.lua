function StartAPI()
    local FeatherWeaponsAPI = {}

    FeatherWeaponsAPI.GiveWeapons = GiveWeaponsAPI

    exports('initiate', function()
        return FeatherWeaponsAPI
    end)
end