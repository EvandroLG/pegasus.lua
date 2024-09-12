local socket = require 'socket'
local Handler = require 'pegasus.handler'

local Pegasus = {}
Pegasus.__index = Pegasus

function Pegasus:new(params)
  params = params or {}
  local server = {}

  server.host = params.host or '*'
  server.port = params.port or '9090'
  server.location = params.location or ''
  server.plugins = params.plugins or {}
  server.timeout = params.timeout or 1
  server.log = params.log or require('pegasus.log')

  return setmetatable(server, self)
end

function Pegasus:start(callback)
  local handler = Handler:new(callback, self.location, self.plugins, self.log)
  local server = assert(socket.bind(self.host, self.port))
  local ip, port = server:getsockname()

  print('Pegasus is up on ' .. ip .. ":".. port) -- needed in case no LuaLogging is available
  handler.log:info('Pegasus is up on %s:%s', ip, port)

  while 1 do
    local client, errmsg = server:accept()

    if client then
      client:settimeout(self.timeout, 'b')
      handler:processRequest(self.port, client, server)
    else
      handler.log:error('Failed to accept connection: %s', errmsg)
    end
  end
end

return Pegasus
