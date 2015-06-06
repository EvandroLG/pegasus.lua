local socket = require 'socket'
local Handler = require 'pegasus.handler'


local Pegasus = {}

function Pegasus:new(params)
  local server = {}
  self.__index = self

  local port, location
  if type(params) == 'table' then
    port = params.port
    location = params.location
    head = params.head
  end

  server.port = port or '9090'
  server.location = location or ''
  server.head = head or {}

  return setmetatable(server, self)
end

function Pegasus:start(callback)
  local handler = Handler:new(callback, self.location)
  local server = assert(socket.bind('*', self.port))
  local ip, port = server:getsockname()
  print('Pegasus is up on ' .. ip .. ":".. port)

  while 1 do
    local client = server:accept()
    client:settimeout(1, 'b')
    handler:processRequest(client, self.head)
    client:close()
  end
end

return Pegasus

