local socket = require 'socket'
local Handler = require 'pegasus.handler'

local Pegasus = {}

function Pegasus:new(port)
  local server = {}
  self.__index = self
  server.port = port or '9090'
  
  return setmetatable(server, self)
end

function Pegasus:start(callback)
  local hdlr = Handler:new(callback)
  local server = assert(socket.bind('*', self.port))
  local ip, port = server:getsockname()
  print('Pegasus is up on ' .. ip .. ":".. port)

  while 1 do
    local client = server:accept()
    client:settimeout(1, 'b')
    hdlr:processRequest(client)
    client:close()
  end
end

return Pegasus
