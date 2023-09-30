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
  "/client/functions.lua",
  "/client/client.lua"
}

dependencies {
  "feather-core"
}

--Version Checking
name 'feather-weapons'
version '0.0.1'
github_version_check 'true'
github_version_type 'release' --OR file
github_link 'https://github.com/jakeyboi1/feather-weapons'