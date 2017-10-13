local socket = require 'socket'
local Handler = require 'pegasus.handler'


local Pegasus = {}

function Pegasus:new(params)
  params = params or {}
  local server = {}
  self.__index = self

  server.port = params.port or '9090'
  server.location = params.location or ''
  server.plugins = params.plugins or {}

  return setmetatable(server, self)
end

function Pegasus:start(callback)
  local handler = Handler:new(callback, self.location, self.plugins)
  local server = assert(socket.bind('*', self.port))
  local ip, port = server:getsockname()
  print('Pegasus is up on ' .. ip .. ":".. port)

  while 1 do
    local client = server:accept()
    client:settimeout(1, 'b')
    handler:processRequest(self.port, client)
  end
end

return Pegasus

