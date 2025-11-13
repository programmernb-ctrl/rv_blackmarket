fx_version 'cerulean'
lua54 'yes'
game 'gta5'
name 'rv_blackmarket'
author 'progammernb-ctrl aka thirst'
version '1.0.3'
repository 'https://github.com/programmernb-ctrl/rv_blackmarket'
description 'blackmarket script to sell/buy illegal ingame items'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua'
}

client_script 'client.lua'

server_scripts {
    'server/inventory/*.lua',
    'server/main.lua',
}

files {
    'locales/*.json'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}

ox_lib 'locale'
