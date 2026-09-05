WeaponDefinitionCatalog = WeaponDefinitionCatalog or {}

-- Each attachment defines: id, itemName, label, slot,
-- nativeComponentName, conflicts, removable, and optional tags.
WeaponDefinitionCatalog.attachments = {
    cattleman_long_barrel = {
        id = "cattleman_long_barrel",
        kind = "attachment",
        itemName = "cattleman_long_barrel",
        label = "Cattleman Long Barrel",
        slot = "barrel",
        nativeComponentName = "COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG",
        conflicts = {},
        removable = true,
        tags = { "functional", "cattleman" }
    }
}
