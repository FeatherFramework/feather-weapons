-- Pure enrollment policy. Callers must still enforce runtime, DevMode, session,
-- epoch and ownership authorization. No automatic/global enrollment or grants.
WeaponNativeEnrollment={}
function WeaponNativeEnrollment.Validate(config)
    if type(config)~='table' then return nil,'native_enrollment_config_required' end
    local members,count={},0
    local single=config.NativeAlphaCharacterId
    -- Preserve the existing explicit single-character contract.
    if single~=nil then
        if type(single)~='string' or #single<1 or #single>128 then return nil,'native_enrollment_single_invalid' end
        members[single]=true; count=1
    end
    local additional=config.NativeAlphaAdditionalCharacters
    if additional~=nil then
        if type(additional)~='table' then return nil,'native_enrollment_list_invalid' end
        for id,allowed in pairs(additional) do
            if type(id)~='string' or allowed~=true or #id~=36
                or not id:match('^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$') then
                return nil,'native_enrollment_entry_invalid'
            end
            if not members[id] then members[id]=true; count=count+1 end
            if count>2 then return nil,'native_enrollment_limit_exceeded' end
        end
    end
    if count==0 then return nil,'native_enrollment_empty' end
    return members
end
function WeaponNativeEnrollment.Allows(config,characterId)
    if type(characterId)~='string' then return false end
    local members=WeaponNativeEnrollment.Validate(config)
    return members~=nil and members[characterId]==true
end

WeaponConstants = {
    ContractVersion = 1,
    MetadataSchemaVersion = 2,
    DefinitionKinds = {
        weapon = true,
        ammunition = true,
        attachment = true
    },
    LoadoutSlots = {
        "utility", "utility_secondary", "utility_tertiary", "utility_quaternary", "utility_quinary", "utility_senary","utility_septenary", "utility_octonary", "primary", "offhand", "shoulder", "back",
        "melee", "melee_secondary", "melee_tertiary", "melee_quaternary", "melee_quinary",
        "throwable", "throwable_secondary", "throwable_tertiary", "throwable_quaternary", "throwable_quinary", "throwable_senary", "throwable_septenary", "throwable_octonary", "throwable_nonary", "throwable_denary"
    },
    UtilitySlots = { utility = true, utility_secondary = true, utility_tertiary = true, utility_quaternary = true, utility_quinary = true, utility_senary = true, utility_septenary = true, utility_octonary = true },
    SidearmSlots = { primary = true, offhand = true },
    LonggunSlots = { shoulder = true, back = true },
    MeleeSlots = {
        melee = true, melee_secondary = true, melee_tertiary = true, melee_quaternary = true, melee_quinary = true
    },
    ThrowableSlots = { throwable = true, throwable_secondary = true, throwable_tertiary = true, throwable_quaternary = true, throwable_quinary = true, throwable_senary = true, throwable_septenary = true, throwable_octonary = true, throwable_nonary = true, throwable_denary = true },
    WeaponSlots = {
        utility = true,
        melee = true,
        sidearm = true,
        longgun = true,
        throwable = true
    },
    AttachmentSlots = {
        barrel = true,
        grip = true,
        magazine = true,
        muzzle = true,
        sight = true,
        stock = true,
        wrap = true
    }
}
