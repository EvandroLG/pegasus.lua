local socket = require 'socket'
local Request = require 'pegasus.request'
local Response = require 'pegasus.response'


local Pegasus = {}

function Pegasus:new(port, location)
  self.port = port or '9090'
  self.location = location or ''

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
    response:processes(request, self.location)
  end

  if callback then
    self:executeCallback(callback, request, response, client)
  else
    client:send(response.body)
  end
end

Pegasus.wasFinishCalled = false

function Pegasus:executeCallback(callback, request, response, client)
  local req = self:makeRequest(request)
  local rep = self:makeResponse(response, client)

  callback(req, rep)

  if not self.wasFinishCalled then
    client:send(response.body)
  end
end

function Pegasus:makeRequest(request)
  return {
    path = request:path(),
    headers = request:headers(),
    method = request:method(),
    querystring = request:params(),
    post = request:post()
  }
end

function Pegasus:makeResponse(response, client)
  rep = {
    statusCode = nil,
    head = nil,

    writeHead = function(statusCode)
      rep.head = response:makeHead(statusCode)
      rep.statusCode = statusCode

      return rep
    end,

    finish = function(body)
      local body = response:createBody(rep.head, body, rep.statusCode)
      client:send(body)
      self.wasFinishCalled = true
    end
  }

  return rep
end

return Pegasus
