fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'J0K3R'
description 'Interactions resource for RedM - sit on chairs, benches, beds, take baths, play piano, and more.'
version '1.0.0'

lua54 'yes'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/font.ttf',
    'ui/logo.png'
}

client_scripts {
    'config.lua',
    'locales/de.lua',
    'locales/en.lua',
    'client/utils.lua',
    'shared/objects.lua',
    'shared/interactions.lua',
    'client/main.lua'
}

server_script 'server/banner.lua'
