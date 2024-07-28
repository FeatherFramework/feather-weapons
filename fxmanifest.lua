fx_version "adamant"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

description "The weapon system for the Feather framework."
author "Feather @Jake2k4"
name "feather-weapons"
version "0.1.1"

github_version_check 'true'
github_version_type 'release'
github_ui_check 'false'
github_link 'https://github.com/FeatherFramework/feather-weapons'

shared_scripts {
  '/shared/data/*.lua',
  "config.lua"
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  "/server/imports.lua",
  "/server/services/*.lua",
  "/server/main.lua"
}

client_scripts {
  "/client/imports.lua",
  "/client/services/*.lua",
  "/client/main.lua"
}

dependencies {
  "oxmysql",
  "feather-core",
  "feather-character",
  "feather-inventory"
}