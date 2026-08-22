WeaponValidation = {}

local function IsNonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function AddError(errors, path, message)
    errors[#errors + 1] = { path = path, message = message }
end

local function IsArray(value)
    if type(value) ~= "table" then return false end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
        count = count + 1
    end
    return count == #value
end

function WeaponValidation.Definition(definition, expectedKind)
    local errors = {}
    if type(definition) ~= "table" then
        return false, { { path = "$", message = "definition must be a table" } }
    end

    if not IsNonEmptyString(definition.id) then AddError(errors, "id", "must be a non-empty string") end
    if definition.kind ~= expectedKind then AddError(errors, "kind", "must equal " .. tostring(expectedKind)) end
    if not IsNonEmptyString(definition.itemName) then AddError(errors, "itemName", "must be a non-empty string") end
    if not IsNonEmptyString(definition.label) then AddError(errors, "label", "must be a non-empty string") end

    if expectedKind == "weapon" then
        if not IsNonEmptyString(definition.nativeWeaponName) then AddError(errors, "nativeWeaponName", "must be a non-empty string") end
        if not WeaponConstants.WeaponSlots[definition.slot] then AddError(errors, "slot", "is not supported") end
        if not IsNonEmptyString(definition.ammunitionType) then AddError(errors, "ammunitionType", "must reference ammunition") end
        if type(definition.capacity) ~= "number" or definition.capacity < 1 or definition.capacity % 1 ~= 0 then
            AddError(errors, "capacity", "must be a positive integer")
        end
        if type(definition.condition) ~= "table"
            or type(definition.condition.minimum) ~= "number"
            or type(definition.condition.maximum) ~= "number"
            or type(definition.condition.equipMinimum) ~= "number"
            or definition.condition.minimum > definition.condition.equipMinimum
            or definition.condition.equipMinimum > definition.condition.maximum then
            AddError(errors, "condition", "must define ordered minimum, equipMinimum, and maximum values")
        end
    elseif expectedKind == "ammunition" then
        if not IsNonEmptyString(definition.nativeAmmoName) then AddError(errors, "nativeAmmoName", "must be a non-empty string") end
    end

    return #errors == 0, errors
end

function WeaponValidation.Metadata(metadata, definition)
    local errors = {}
    if type(metadata) ~= "table" then
        return false, { { path = "$", message = "metadata must be a table" } }
    end
    if tonumber(metadata.schemaVersion) ~= WeaponConstants.MetadataSchemaVersion then
        AddError(errors, "schemaVersion", "is unsupported")
    end
    if metadata.weaponDefinitionId ~= definition.id then
        AddError(errors, "weaponDefinitionId", "does not match the weapon definition")
    end
    if definition.policies.serialRequired and not IsNonEmptyString(metadata.serialNumber) then
        AddError(errors, "serialNumber", "is required")
    end

    local condition = tonumber(metadata.condition)
    if not condition or condition < definition.condition.minimum or condition > definition.condition.maximum then
        AddError(errors, "condition", "is outside the definition bounds")
    end

    if type(metadata.ammo) ~= "table" then
        AddError(errors, "ammo", "must be a table")
    else
        local loaded = tonumber(metadata.ammo.loaded)
        if not loaded or loaded < 0 or loaded > definition.capacity or loaded % 1 ~= 0 then
            AddError(errors, "ammo.loaded", "must be an integer within weapon capacity")
        end
        if type(metadata.ammo.chambered) ~= "boolean" then
            AddError(errors, "ammo.chambered", "must be boolean")
        end
    end

    if not IsArray(metadata.attachments) then AddError(errors, "attachments", "must be an array") end
    if type(metadata.cosmetics) ~= "table" then AddError(errors, "cosmetics", "must be a table") end
    if type(metadata.flags) ~= "table" then
        AddError(errors, "flags", "must be a table")
    else
        for _, key in ipairs({ "stolen", "evidence", "disabled" }) do
            if type(metadata.flags[key]) ~= "boolean" then AddError(errors, "flags." .. key, "must be boolean") end
        end
    end

    return #errors == 0, errors
end
