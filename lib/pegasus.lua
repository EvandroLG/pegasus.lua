local socket = require 'socket'
local Request = require 'lib/request'
local Response = require 'lib/response'
local http = require 'lib/http'


local Pegasus = {}

function Pegasus:new(port)
  self.port = port or '9090'
  return self
end

function Pegasus:start(callback)
  local server = assert(socket.bind("*", self.port))
  local ip, port = server:getsockname()
  print("Server is up on port " .. self.port)
  local was_called = false

  while 1 do
    local client = server:accept()

    client:settimeout(30)

    if not was_called then
      self:processRequest(client, callback)
      was_called = true
    else
      self:processRequest(client)
    end

    client:close()
  end
end

function Pegasus:processRequest(client, callback)
  local request = Request:new(client)
  local response =  Response:new(client)
  local method = request:method()

  if method == 'GET' then
    self:GET(request, response, callback)
  elseif method == 'POST' then
    self:POST(request, response)
  end

  client:send(response.body)
end

function Pegasus:GET(request, response, callback)
  response:processes(request, response)

  if callback then
    callback(request, response)
  end
end

function Pegasus:POST(request, response)
  print('POST')
  response:processes(request)
end

return Pegasus
-- httpServer = HTTPServer:new('9090')

-- httpServer:start(function (req, rep)
--   print(req:params()['name'])
-- end)
