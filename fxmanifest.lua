fx_version "cerulean"
games { "rdr3" }
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

description "The weapon system for the Feather framework."
author "Feather Framework"
name "feather-weapons"
version "0.2.0-dev"

github_version_check "true"
github_version_type "release"
github_ui_check "false"
github_link "https://github.com/FeatherFramework/feather-weapons"

shared_scripts {
    "config.lua",
    "/shared/constants.lua",
    "/shared/errors.lua",
    "/shared/definitions.lua",
    "/shared/validation.lua"
}

server_scripts {
    "/server/imports.lua",
    "/server/adapters/core.lua",
    "/server/adapters/inventory.lua",
    "/server/services/definition_registry.lua",
    "/server/services/metadata.lua",
    "/server/adapters/test_inventory.lua",
    "/server/services/runtime.lua",
    "/server/services/equip.lua",
    "/server/services/ammo.lua",
    "/server/services/reconciliation.lua",
    "/server/services/api.lua",
    "/server/main.lua"
}

client_scripts {
    "/client/imports.lua",
    "/client/main.lua"
}

dependencies {
    "feather-core"
}
