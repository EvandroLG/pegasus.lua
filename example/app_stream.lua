-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'
local socket = require 'socket'

local server = Pegasus:new({
  port='9090'
})
local function sleep(sec)
  socket.select(nil, nil, sec)
end

server:start(function(req, res)
   res:write('a', true)
   sleep(3)
   res:write('b', true)
   sleep(3)
   res:write('c', true)
   res:close()
end)
