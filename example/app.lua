-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'
local Compress = require 'pegasus.compress'
local Cache = require 'pegasus.cache'

local server = Pegasus:new({
  port='9090',
  location='/example/root/',
  plugins = {Compress:new(), Cache:new()}
})

server:start(function(req, rep)
end)
