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

  if self.callback then
    self.callback(self:makeRequest(request), response)
  elseif request:path() then
    response:_process(request, self.location)
  end

  client:send(response.content)
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

return Handler
