local socket = require 'socket'
local Handler = require 'pegasus.handler'


local Pegasus = {}

function Pegasus:new(params)
  params = params or {}
  local server = {}
  self.__index = self

  local port, location
  server.port = params.port or '9090'
  server.location = params.location or ''
  server.plugins = params.plugins or {}

  return setmetatable(server, self)
end

function Pegasus:prepare(callback, talk)
  self.handler = Handler:new(callback, self.location, self.plugins)
  self.server = assert(socket.bind('*', self.port))
  local ip, port = self.server:getsockname()
  if talk == nil or talk then
     print('Pegasus is up on http://' .. ip .. ":".. port)
  end
end

function Pegasus:iterate()
  local client = self.server:accept()
  client:settimeout(1, 'b')
  self.handler:processRequest(client)
end

function Pegasus:start(callback, talk)
  self:prepare(callback, talk)

  while 1 do self:iterate() end
end

return Pegasus

