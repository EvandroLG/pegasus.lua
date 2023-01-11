-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'

local server = Pegasus:new()

server:start(function (req, res)
  res:addHeader('Content-Type', 'text/html'):write('hello pegasus world!')
end)
