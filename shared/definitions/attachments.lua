WeaponDefinitionCatalog = WeaponDefinitionCatalog or {}

-- Each attachment defines: id, itemName, label, slot,
-- nativeComponentName, conflicts, prerequisites, removable, and optional tags.
WeaponDefinitionCatalog.attachments = {
    cattleman_long_barrel = {
        id = "cattleman_long_barrel",
        kind = "attachment",
        itemName = "cattleman_long_barrel",
        label = "Cattleman Long Barrel",
        slot = "barrel",
        nativeComponentName = "COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG",
        conflicts = {},
        prerequisites = {},
        removable = true,
        tags = { "functional", "cattleman" }
    },
    cattleman_wide_sight = {
        id = "cattleman_wide_sight",
        kind = "attachment",
        itemName = "cattleman_wide_sight",
        label = "Cattleman Wide Sight",
        slot = "sight",
        nativeComponentName = "COMPONENT_REVOLVER_CATTLEMAN_SIGHT_WIDE",
        conflicts = {},
        prerequisites = {},
        removable = true,
        tags = { "functional", "cattleman" }
    },
    schofield_short_barrel = {
        id = "schofield_short_barrel",
        kind = "attachment",
        itemName = "schofield_short_barrel",
        label = "Schofield Short Barrel",
        slot = "barrel",
        nativeComponentName = "COMPONENT_REVOLVER_SCHOFIELD_BARREL_SHORT",
        conflicts = {},
        prerequisites = {},
        removable = true,
        tags = { "functional", "schofield" }
    },
    schofield_wide_sight = {
        id = "schofield_wide_sight",
        kind = "attachment",
        itemName = "schofield_wide_sight",
        label = "Schofield Wide Sight",
        slot = "sight",
        nativeComponentName = "COMPONENT_REVOLVER_SCHOFIELD_SIGHT_WIDE",
        conflicts = {},
        prerequisites = {},
        removable = true,
        tags = { "functional", "schofield" }
    }
}
