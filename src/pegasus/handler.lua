local Request = require 'pegasus.request'
local Response = require 'pegasus.response'


local Handler = {}

function Handler:new(callback, location)
  local handler = {}
  self.__index = self
  handler.callback = callback
  handler.location = location or ''

  return setmetatable(handler, self)
end

function Handler:processRequest(client, plugins)
  local request = Request:new(client)
  local response =  Response:new()

  if request:path() then
    response:_process(request, self.location)
  end

  if self.callback then
    response:statusCode(200)
    response.headers = {}
    response:addHeader('Content-Type', 'text/html')
    self.callback(self:makeRequest(request), response)
  end

  client:send(response.content)
end

function Handler:makeRequest(request)
  return {
    path = request:path(),
    headers = request:headers(),
    method = request:method(),
    querystring = request:params(),
    post = request:post() or {}
  }
end

return Handler
