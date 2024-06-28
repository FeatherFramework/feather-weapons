fx_version "adamant"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

lua54 "yes"

shared_scripts {
  "config.lua"
}

server_scripts {
  "/server/server.lua"
}

client_scripts {
  "/client//helpers/functions.lua",
  "/client/services/giveWeapons.lua",
  "/client/services/api.lua",
  '/client/main.lua'
}

dependencies {
  "feather-core",
  "feather-inventory"
}