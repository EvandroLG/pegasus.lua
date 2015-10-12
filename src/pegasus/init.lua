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

function Pegasus:prepare(callback)
  if not self.server then
    self.handler = Handler:new(callback, self.location, self.plugins)
    self.server = assert(socket.bind('*', self.port))
  end
end

function Pegasus:iterate()
  local client = self.server:accept()
  if client then
     client:settimeout(1, 'b')
     self.handler:processRequest(client)
  end
end

function Pegasus:start(callback, talk)
  self:prepare(callback)

  if talk == nil or talk then  -- NOTE/TODO: modules can make it https? They redirect?
    local ip, port = self.server:getsockname()
    print('Pegasus is up on http://' .. ip .. ":".. port)
  end
  while true do self:iterate() end
end

return Pegasus

