-- package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Handler   = require 'pegasus.handler'
local KeepAlive = require 'pegasus.handler'
local copas     = require 'copas'
local socket    = require 'socket'

local CopasKeepAlive = setmetatable({}, KeepAlive) do
CopasKeepAlive.__index = CopasKeepAlive

local function is_copas_socket_alive(s)
  return s and s.socket and s.socket.getfd and s.socket:getfd() ~= -1
end

function CopasKeepAlive:new(opt)
  local o = KeepAlive.new(self, opt)

  o._socket_test = is_copas_socket_alive

  return o
end

end

local handler = Handler:new(function(req, rep)
  print(req, ' - precess')
  rep:statusCode(200)
  rep:write('Hello pegasus world!')
end, nil, {
  CopasKeepAlive:new{
    wait_timeout    = 60;
    request_timeout = 5;
    requests        = 10;
    connections     = 10;
  }
})

-- Create http server
local server = assert(socket.bind('*', 9090))
local ip, port = server:getsockname()

copas.addserver(server, copas.handler(function(skt)
  handler:processRequest(9090, skt)
end))

print('Pegasus is up on ' .. ip .. ":".. port)

-- Start
copas.loop()
