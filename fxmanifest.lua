fx_version 'cerulean'
game 'gta5'

author 'Distortionz'
description 'Premium custom Qbox banking system for Distortionz RP'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
    'version_check.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core'
}
