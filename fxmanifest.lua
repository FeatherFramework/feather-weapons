fx_version "adamant"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

lua54 "yes"

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
  "feather-core",
  "feather-inventory"
}