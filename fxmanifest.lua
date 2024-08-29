fx_version 'adamant'
games { 'gta5' }
dependency 'chat'
lua54 'yes'
version '1.0.0'
author 'TheStoicBear | ValenciaModifcations'
description 'Stoic-PoliceMenu'

client_scripts {
    'source/search/search_c.lua',
    'source/citation/citation_c.lua',
    'source/jail/jail_c.lua',
    'source/gsr/gsr_c.lua',
    'source/gsr/gsr_m.lua',
    'source/main_c.lua',
    'source/actions/client.lua'
}

server_scripts {
    'source/search/search_s.lua',
    'source/citation/citation_s.lua',
    'source/gsr/gsr_s.lua',
    'source/main_s.lua',
    'source/jail/jail_s.lua',
    'source/actions/server.lua'
} 

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
} 
