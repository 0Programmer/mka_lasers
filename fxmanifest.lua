--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'mka_lasers'
version      '2.0.0'
repository   'https://github.com/0Programmer/mka_lasers'
description  'Create moving lasers in FiveM!'

--[[ Manifest ]]--
shared_scripts {
  '@ox_lib/init.lua',
}
server_scripts {
  'server/creation.lua'
}
client_scripts {
  'client/utils.lua',
  'client/client.lua',
  'client/creation.lua'
}