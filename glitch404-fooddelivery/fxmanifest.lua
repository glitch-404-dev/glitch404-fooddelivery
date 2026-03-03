fx_version 'cerulean'
game 'gta5'

author 'Glitch-404'
description 'Food Delivery Job (QB + ox)'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'qbx_core',
    'ox_target',
    'ox_inventory',
    'ox_lib'
}