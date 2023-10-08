fx_version "adamant"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

lua54 "yes"

shared_scripts {
  "config.lua"
}

server_scripts {
  "/server/helpers/functions.lua",
  "/server/main.lua"
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

--Version Checking
name 'feather-weapons'
version '0.0.1'
github_version_check 'true'
github_version_type 'release' --OR file
github_link 'https://github.com/jakeyboi1/feather-weapons'