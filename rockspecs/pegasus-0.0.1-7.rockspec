package = 'pegasus'
version = '0.0.1-7'

source = {
  url = 'git://github.com/evandrolg/pegasus.lua.git',
  tag = 'v0.0.7'
}

description = {
  summary = 'Pegasus.lua is a http server to work with web applications written in Lua language.',
  homepage = 'https://github.com/EvandroLG/pegasus.lua',
  maintainer = 'Evandro Leopoldino Gonçalves (@evandrolg) <evandrolgoncalves@gmail.com>',
  license = 'MIT <http://opensource.org/licenses/MIT>'
}

dependencies = {
  "lua >= 5.1",
  "mimetypes >= 1.0.0-1",
  "luasocket >= 0.1.0-0",
  "luafilesystem >= 1.6",
}

build = {
  type = "builtin",
  modules = {
    ['pegasus.init']     = "src/pegasus/init.lua",
    ['pegasus.handler']  = 'src/pegasus/handler.lua',
    ['pegasus.request']  = 'src/pegasus/request.lua',
    ['pegasus.response'] = 'src/pegasus/response.lua',
    ['pegasus.file']     = 'src/pegasus/file.lua'
  }
}
