local Request = require 'pegasus.request'
local Response = require 'pegasus.response'


local Handler = {}

function Handler:new(callback)
  local hdlr = {}
  self.__index = self
  hdlr.callback = callback

  return setmetatable(hdlr, self)
end

function Handler:processRequest(client)
  local request = Request:new(client)
  local response =  Response:new(client)

  if request:path() then
    response:processes(request)
  end

  if self.callback then
    self:execute(request, response, client)
  else
    client:send(response.body)
  end
end

Handler.wasFinishCalled = false

function Handler:execute(request, response, client)
  local req = self:makeRequest(request)
  local rep = self:makeResponse(response, client)

  self.callback(req, rep)

  if not self.wasFinishCalled then
    client:send(response.body)
  end
end

function Handler:makeRequest(request)
  return {
    path = request:path(),
    headers = request:headers(),
    method = request:method(),
    querystring = request:params(),
    post = request:post()
  }
end

function Handler:makeResponse(response, client)
  local rep
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

return Handler
