-- setup path to find the project source files of Pegasus
package.path = "../src/?.lua;../src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'

local server = Pegasus:new('9090', '/example/')

server:start(function (req, rep)
  --rep.writeHead(200).finish('hello pegasus world!')
end)
