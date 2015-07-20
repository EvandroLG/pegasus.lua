local Request = require 'pegasus.request'
local Response = require 'pegasus.response'
local mimetypes = require 'mimetypes'
local lfs = require 'lfs'


local Handler = {}

function Handler:new(callback, location, plugins)
  local handler = {}
  self.__index = self
  handler.callback = callback
  handler.location = location or ''
  handler.plugins = plugins or {}

  local result = setmetatable(handler, self)
  result:pluginsalterRequestResponseMetatable()
  return result
end

function Handler:pluginsalterRequestResponseMetatable()
  local stop = false
  for i, plugin in ipairs(self.plugins) do
    if plugin.alterRequestResponseMetaTable then
      plugin:alterRequestResponseMetaTable(Request, Response)
    end
  end
end


function Handler:pluginsNewRequestResponse(request, response)
  local stop = false
  for i, plugin in ipairs(self.plugins) do
    if plugin.newRequestResponse then
      plugin:newRequestResponse(request, response)
    end
  end
end

function Handler:pluginsBeforeProcess(request, response)
  local stop = false
  for i, plugin in ipairs(self.plugins) do
    if plugin.beforeProcess then
      stop = plugin:beforeProcess(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsAfterProcess(request, response)
  local stop = false
  for i, plugin in ipairs(self.plugins) do
    if plugin.afterProcess then
      plugin:afterProcess(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsProcessFile(request, response, filename)
  local stop = false
  for i, plugin in ipairs(self.plugins) do
    if plugin.processFile then
      stop = plugin:processFile(request, response, filename)
      if stop then
        return stop
      end
    end
  end
end

function Handler:processBodyData(data, stayOpen, response)
  local local_data = data
  for i, plugin in ipairs(self.plugins) do
    if plugin.processBodyData then
      local_data = plugin:processBodyData(local_data, stayOpen,
        response.request,  response)
    end
  end
  return local_data
end

function Handler:processRequest(client)
  local request = Request:new(client)
  local response =  Response:new(client, self)
  response.request = request
  local stop = false

  local stop = self:pluginsNewRequestResponse(request, response)
  if stop then
    return
  end
  if request:path() and self.location ~= '' then
    filename = '.' .. self.location .. request:path()
    if not lfs.attributes(filename) then
      response:statusCode(404)
      return
    end
    stop = self:pluginsProcessFile(request, response, filename)
    if stop then
        return
    end
    local file = io.open(filename, 'rb')
    if file then
      response:writeFile(file, mimetypes.guess(filename or '') or 'text/html')
    end
  end

  if self.callback then
    response:statusCode(200)
    response.headers = {}
    response:addHeader('Content-Type', 'text/html')
    self.callback(request, response)
  end
end


return Handler
