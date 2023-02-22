-- setup path to find the project source files of Pegasus
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

local Pegasus = require 'pegasus'
local Compress = require 'pegasus.plugins.compress'
local Downloads = require 'pegasus.plugins.downloads'

local server = Pegasus:new({
  port = '9090',
  location = '/example/root/',
  plugins = {
    Downloads:new {
      prefix = "downloads",
      stripPrefix = true,
    },
    Compress:new(),
  }
})

server:start(function(req)
  local data = req:post()

  if data then
    print(data['name'])
    print(data['age'])
  end
end)
