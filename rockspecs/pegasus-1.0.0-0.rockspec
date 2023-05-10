local package_name = "pegasus"
local package_version = "1.0.0"
local rockspec_revision = "0"
local github_account_name = "evandrolg"
local github_repo_name = "pegasus.lua"


package = package_name
version = package_version.."-"..rockspec_revision

source = {
  url = "git+https://github.com/"..github_account_name.."/"..github_repo_name..".git",
  branch = (package_version == "dev") and "master" or nil,
  tag = (package_version ~= "dev") and ("v"..package_version) or nil,
}

description = {
  summary = 'Pegasus.lua is an http server to work with web applications written in Lua language.',
  maintainer = 'Evandro Leopoldino Gonçalves (@evandrolg) <evandrolgoncalves@gmail.com>',
  license = 'MIT <http://opensource.org/licenses/MIT>',
  homepage = "https://github.com/"..github_account_name.."/"..github_repo_name,
}

dependencies = {
  "lua >= 5.1",
  "mimetypes >= 1.0.0-1",
  "luasocket >= 0.1.0-0",
  "luafilesystem >= 1.6",
  "lzlib >= 0.4.1.53-1",
}

build = {
  type = "builtin",
  modules = {
    ['pegasus.init']     = "src/pegasus/init.lua",
    ['pegasus.handler']  = 'src/pegasus/handler.lua',
    ['pegasus.request']  = 'src/pegasus/request.lua',
    ['pegasus.response'] = 'src/pegasus/response.lua',
    ['pegasus.compress'] = 'src/pegasus/compress.lua',
    ['pegasus.plugins.compress'] = 'src/pegasus/plugins/compress.lua',
    ['pegasus.plugins.downloads'] = 'src/pegasus/plugins/downloads.lua',
    ['pegasus.plugins.tls'] = 'src/pegasus/plugins/tls.lua',
  }
}
