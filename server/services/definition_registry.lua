DefinitionRegistry = {}
local registry = { weapon = {}, ammunition = {}, attachment = {} }
local ready = false

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function RegisterGroup(group, kind, errors)
    for key, definition in pairs(group or {}) do
        local valid, definitionErrors = WeaponValidation.Definition(definition, kind)
        if key ~= definition.id then
            definitionErrors[#definitionErrors + 1] = { path = "id", message = "must match catalog key " .. tostring(key) }
            valid = false
        end
        if registry[kind][definition.id] then
            definitionErrors[#definitionErrors + 1] = { path = "id", message = "is duplicated" }
            valid = false
        end
        if not valid then
            errors[#errors + 1] = { kind = kind, key = key, errors = definitionErrors }
        else
            registry[kind][definition.id] = Copy(definition)
        end
    end
end

function DefinitionRegistry.Start()
    registry = { weapon = {}, ammunition = {}, attachment = {} }
    local errors = {}
    RegisterGroup(WeaponDefinitionCatalog.ammunition, "ammunition", errors)
    RegisterGroup(WeaponDefinitionCatalog.attachments, "attachment", errors)
    RegisterGroup(WeaponDefinitionCatalog.weapons, "weapon", errors)

    for id, definition in pairs(registry.weapon) do
        if not registry.ammunition[definition.ammunitionType] then
            errors[#errors + 1] = {
                kind = "weapon",
                key = id,
                errors = { { path = "ammunitionType", message = "references unknown ammunition " .. tostring(definition.ammunitionType) } }
            }
        end
    end

    ready = #errors == 0
    if not ready then
        return WeaponResult.Error(WeaponErrors.INVALID_DEFINITION, "Weapon definitions failed validation", errors)
    end
    return WeaponResult.Ok(DefinitionRegistry.Counts())
end

function DefinitionRegistry.IsReady()
    return ready
end

function DefinitionRegistry.Get(kind, id)
    local group = registry[kind]
    local definition = group and group[id]
    if not definition then
        return WeaponResult.Error(WeaponErrors.DEFINITION_NOT_FOUND, "Definition was not found", { kind = kind, id = id })
    end
    return WeaponResult.Ok(Copy(definition))
end

function DefinitionRegistry.List(kind)
    local result = {}
    for _, definition in pairs(registry[kind] or {}) do result[#result + 1] = Copy(definition) end
    table.sort(result, function(a, b) return a.id < b.id end)
    return WeaponResult.Ok(result)
end

function DefinitionRegistry.Counts()
    local counts = {}
    for kind, group in pairs(registry) do
        local count = 0
        for _ in pairs(group) do count = count + 1 end
        counts[kind] = count
    end
    return counts
end
