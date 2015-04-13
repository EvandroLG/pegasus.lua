local socket = require 'socket'
local Handler = require 'pegasus.handler'


local isNumber = function(value)
  return type(value) == 'number'
end

local isNil = function(value)
  return type(value) == 'nil'
end

local ternary = function(condition, success, failure)
  if condition then return success
  else return failure end
end

local Pegasus = {}

function Pegasus:new(params)
  local server = {}
  self.__index = self

  local port = params.port
  if isNumber(port) then tostring(port) end

  server.port = port or '9090'
  server.location = params.location or ''

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
    handler:processRequest(client)
    client:close()
  end
end

return Pegasus
