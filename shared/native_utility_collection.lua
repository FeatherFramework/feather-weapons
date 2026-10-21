-- Explicitly gated utility collection. Davy gate-off preserves the lasso path.
local U=WeaponNativeUtilityItem
local assignedSingle,prepareSingle=U.AssignedSnapshot,U.Prepare
local function copy(v)
    if type(v)~='table' then return v end
    local r={}; for k,x in pairs(v) do r[k]=copy(x) end; return r
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end; return true
end
function U.Entries(approval)
    if not approval then return {} end
    return approval.items or {approval}
end
function U.ValidateCollection(approval,catalog,bound)
    if not WeaponNativeUtilityCatalog.DavyEnabled() or type(approval)~='table'
        or type(approval.items)~='table' or getmetatable(approval.items)~=nil then return nil,'utility_collection_required' end
    for key in pairs(approval) do if key~='items' then return nil,'utility_collection_required' end end
    local count=0
    for key in pairs(approval.items) do
        if type(key)~='number' or key%1~=0 or key<1 or key>(WeaponNativeUtilityCatalog.CameraEnabled() and 4 or WeaponNativeUtilityCatalog.BinocularsEnabled() and 3 or 2) then return nil,'utility_collection_required' end
        count=count+1
    end
    if count<1 or count~=#approval.items then return nil,'utility_collection_required' end
    local result,slots,ids,families={items={}},{},{},{}
    for _,entry in ipairs(approval.items) do
        local row=type(entry)=='table' and entry.row
        local def=type(row)=='table' and type(row.metadata)=='table' and catalog.weapons[row.metadata.weaponDefinitionId]
        local profile=def and WeaponNativeUtilityCatalog.Resolve(def)
        local valid,why=def and U.ValidateApproval(entry,def,bound)
        if not valid or not profile then return nil,why or 'utility_definition_required' end
        if slots[entry.equipmentSlot] or ids[row.id] or families[profile.family] then return nil,'utility_family_or_assignment_conflict' end
        slots[entry.equipmentSlot],ids[row.id],families[profile.family]=true,true,true
        result.items[#result.items+1]=valid
    end
    table.sort(result.items,function(a,b) return a.equipmentSlot<b.equipmentSlot end)
    return result
end
function U.AssignedSnapshot(snapshot,catalog,bound)
    if not WeaponNativeUtilityCatalog.DavyEnabled() then
        if type(snapshot)=='table' and type(snapshot.equipment)=='table' then
            for _,row in pairs(snapshot.equipment) do
                if type(row)=='table' and type(row.metadata)=='table'
                    and row.metadata.weaponDefinitionId=='utility_davy_lantern' then return nil,'native_davy_lantern_disabled' end
                if type(row)=='table' and type(row.metadata)=='table'
                    and row.metadata.weaponDefinitionId=='utility_binoculars' then return nil,'native_binoculars_disabled' end
                if type(row)=='table' and type(row.metadata)=='table'
                    and row.metadata.weaponDefinitionId=='utility_camera' then return nil,'native_camera_disabled' end
            end
        end
        return assignedSingle(snapshot,catalog,bound)
    end
    if type(snapshot)~='table' or type(bound)~='table' or snapshot.characterId~=bound.characterId
        or type(snapshot.equipment)~='table' or type(snapshot.expected)~='table' then return nil,'utility_snapshot_required' end
    local items={}
    for slot,row in pairs(snapshot.equipment) do
        if type(slot)~='string' or not WeaponNativeUtilityCatalog.Slots()['weapon_'..slot] then return nil,'unsupported_utility_slot' end
        if type(row)~='table' then return nil,'utility_row_required' end
    end
    for slot,expected in pairs(snapshot.expected) do
        if type(slot)~='string' then return nil,'utility_assignment_changed' end
        if slot:match('^weapon_utility') and not WeaponNativeUtilityCatalog.Slots()[slot] then return nil,'unsupported_utility_slot' end
    end
    local order={'utility','utility_secondary'}
    if WeaponNativeUtilityCatalog.BinocularsEnabled() then order[#order+1]='utility_tertiary' end
    if WeaponNativeUtilityCatalog.CameraEnabled() then order[#order+1]='utility_quaternary' end
    for _,slot in ipairs(order) do
        local row,expected=snapshot.equipment[slot],snapshot.expected['weapon_'..slot]
        if row~=nil or expected~=nil then
            if type(row)~='table' or type(expected)~='table' or expected.itemId~=row.id or expected.revision~=row.revision then return nil,'utility_assignment_changed' end
            for other,entry in pairs(snapshot.expected) do
                if other~='weapon_'..slot and type(entry)=='table' and entry.itemId==row.id then return nil,'utility_duplicate_assignment' end
            end
            items[#items+1]={identity=copy(bound),equipmentSlot='weapon_'..slot,row=copy(row)}
        end
    end
    if #items==0 then return false end
    return U.ValidateCollection({items=items},catalog,bound)
end
function U.Prepare(snapshot,def,bound,intent)
    if not WeaponNativeUtilityCatalog.DavyEnabled() then return prepareSingle(snapshot,def,bound,intent) end
    if type(bound)~='table' or type(snapshot)~='table' or type(intent)~='table' or not WeaponNativeUtilityCatalog.Slots()[intent.slot]
        or (intent.action~='equip' and intent.action~='unequip') or type(snapshot.expected)~='table'
        or type(snapshot.equipment)~='table' or type(snapshot.utilityEquipment)~='table'
        or snapshot.characterId~=bound.characterId
        or not same(snapshot.expected,snapshot.utilityEquipment.expected) then return nil,'utility_transition_snapshot_changed' end
    for key in pairs(intent) do
        if key~='slot' and key~='action' and key~='itemId' and key~='selectedItemId' then return nil,'invalid_utility_intent' end
    end
    local assigned,why=U.AssignedSnapshot(snapshot.utilityEquipment,WeaponDefinitionCatalog,bound)
    if assigned==nil then return nil,why end
    local row
    if intent.action=='equip' then
        row=snapshot.candidate
        if type(row)~='table' or intent.itemId~=row.id or (intent.selectedItemId and intent.selectedItemId~=row.id)
            or snapshot.expected[intent.slot] then return nil,'utility_candidate_or_slot_changed' end
        local profile=WeaponNativeUtilityCatalog.Resolve(def)
        if not profile or not U.Project(row,def,bound) then return nil,'utility_candidate_required' end
        if (intent.slot=='weapon_utility_tertiary')~=(profile.id=='utility_binoculars') then return nil,'utility_profile_slot_mismatch' end
        if (intent.slot=='weapon_utility_quaternary')~=(profile.id=='utility_camera') then return nil,'utility_profile_slot_mismatch' end
        for _,entry in pairs(snapshot.expected) do if entry.itemId==row.id then return nil,'utility_already_equipped' end end
        for _,entry in ipairs(U.Entries(assigned)) do
            local existing=WeaponDefinitionCatalog.weapons[entry.row.metadata.weaponDefinitionId]
            if existing.family==profile.family then
                return nil,profile.family=='lasso' and 'one_equipped_lasso_required'
                    or profile.family=='lantern' and 'one_equipped_lantern_required'
                    or profile.family=='camera' and 'one_equipped_camera_required' or 'one_equipped_binoculars_required'
            end
        end
    else
        for _,entry in ipairs(U.Entries(assigned)) do if entry.equipmentSlot==intent.slot then row=entry.row end end
        if not row or intent.itemId~=nil or (intent.selectedItemId and intent.selectedItemId~=row.id)
            or not U.Project(row,def,bound) then return nil,'utility_selected_assignment_changed' end
    end
    return {characterId=bound.characterId,action=intent.action,slot=intent.slot,utility=true,davyFamily=true,
        binocularsFamily=WeaponNativeUtilityCatalog.BinocularsEnabled() or nil,
        cameraFamily=WeaponNativeUtilityCatalog.CameraEnabled() or nil,
        utilityId=row.id,utilityRevision=row.revision,before=copy(row.metadata),expected=copy(snapshot.expected),
        lifecycleSnapshot=copy(snapshot.equipment),brokenEquipmentContract=snapshot.brokenEquipmentContract,
        brokenPromotionContract=snapshot.brokenPromotionContract}
end
