-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'

local server = Pegasus:new()

server:start(function (req, rep)
  rep:write('hello pegasus world!')
end)
