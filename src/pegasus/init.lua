local socket = require 'socket'
local Handler = require 'pegasus.handler'

local Pegasus = {}
Pegasus.__index = Pegasus

-- Create a new Pegasus server
-- @param params.host {string}
-- @param params.port {string}
-- @param params.location {string}
-- @param params.plugins {table}
-- @param params.timeout {number}
-- @return {table}
function Pegasus:new(params)
  params = params or {}
  local server = {}

  server.host = params.host or '*'
  server.port = params.port or '9090'
  server.location = params.location or ''
  server.plugins = params.plugins or {}
  server.timeout = params.timeout or 1

  return setmetatable(server, self)
end

-- Start Pegasus server
-- @param callback {function}
-- @return {nil}
function Pegasus:start(callback)
  local handler = Handler:new(callback, self.location, self.plugins)
  local server = assert(socket.bind(self.host, self.port))
  local ip, port = server:getsockname()
  print('Pegasus is up on ' .. ip .. ":" .. port)

  while 1 do
    local client, errmsg = server:accept()

    if client then
      client:settimeout(self.timeout, 'b')
      handler:processRequest(self.port, client, server)
    else
      io.stderr:write('Failed to accept connection:' .. errmsg .. '\n')
    end
  end
end

return Pegasus
