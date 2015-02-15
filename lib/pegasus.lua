local socket = require 'socket'
local Request = require 'lib/request'
local Response = require 'lib/response'


local Pegasus = {}

function Pegasus:new(port)
  self.port = port or '9090'
  return self
end

function Pegasus:start(callback)
  local server = assert(socket.bind('*', self.port))
  local ip, port = server:getsockname()
  print('Pegasus is up on port ' .. self.port)

  while 1 do
    local client = server:accept()
    client:settimeout(1, 'b')
    self:processRequest(client, callback)
    client:close()
  end
end

function Pegasus:processRequest(client, callback)
  local request = Request:new(client)
  local response =  Response:new(client)

  if request:path() then
    response:processes(request)
  end

  if callback then
    self:executeCallback(callback, request, response)
  end

  client:send(response.body)
end

function Pegasus:executeCallback(callback, request, response)
  local req = {
    path = request:path(),
    headers = request:headers(),
    method = request:method(),
    querystring = request:params(),
    post = request:post()
  }

  local rep = {
    statusCode = nil,
    head = nil,

    writeHead = function(statusCode)
      rep.head = response:makeHead(statusCode)
      rep.statusCode = statusCode
    end,

    finish = function(body)
      response:createBody(rep.head, body, rep.statusCode)
    end
  }

  callback(req, rep)
end

return Pegasus
