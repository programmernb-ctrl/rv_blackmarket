fx_version 'cerulean'
lua54 'yes'
game 'gta5'
name 'rv_blackmarket'
author 'progammernb-ctrl aka thirst'
version '1.0.0'
repository 'https://github.com/programmernb-ctrl/rv_blackmarket'
description 'blackmarket script to sell/buy illegal ingame items'

dependencies {
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua'
}

ox_lib {
    'locale'
}

server_script 'server.lua'

client_script 'client.lua'

files {
    'locales/*.json'
}
