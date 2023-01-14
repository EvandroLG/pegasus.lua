-- setup path to find the project source files of Pegasus
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

local Pegasus = require 'pegasus'
local Compress = require 'pegasus.compress'

local server = Pegasus:new({
  port='9090',
  location='/example/root/',
  plugins = { Compress:new() }
})

server:start(function(req)
  local data = req:post()

  if data then
    print(data['name'])
    print(data['age'])
  end
end)
