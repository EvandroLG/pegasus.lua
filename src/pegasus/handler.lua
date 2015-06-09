local Request = require 'pegasus.request'
local Response = require 'pegasus.response'


local Handler = {}

function Handler:new(callback, location)
  local hdlr = {}
  self.__index = self
  hdlr.callback = callback
  hdlr.location = location or ''

  return setmetatable(hdlr, self)
end

function Handler:processRequest(client, head, plugins)
  local request = Request:new(client)
  local response =  Response:new(client)

  if request:path() then
    response:processes(request, head, self.location)
  end

  if self.callback then
    self:execute(request, response, client, plugins)
  else
    client:send(response.body)
  end
end

Handler.wasFinishCalled = false

function Handler:execute(request, response, client)
  local req = self:makeRequest(request)
  local rep = self:makeResponse(response, client)


  for plugin in ipairs(plugins or {}) do
    if (plugin.before) then
      plugin.before(request, response)
    end
  end

  self.callback(req, rep)

  for plugin in ipairs(plugins or {}) do
    if (plugin.after) then
      plugin.after(request, response)
    end
  end
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
