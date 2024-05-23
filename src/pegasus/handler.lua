local Request = require 'pegasus.request'
local Response = require 'pegasus.response'
local Files = require 'pegasus.plugins.files'

local Handler = {}
Handler.__index = Handler

function Handler:new(callback, location, plugins)
  local handler = {}
  handler.callback = callback
  handler.plugins = plugins or {}

  if location then
    handler.plugins[#handler.plugins+1] = Files:new {
      location = location,
      default = "/index.html",
    }
  end

  local result = setmetatable(handler, self)
  result:pluginsAlterRequestResponseMetatable()

  return result
end

function Handler:pluginsAlterRequestResponseMetatable()
  for _, plugin in ipairs(self.plugins) do
    if plugin.alterRequestResponseMetaTable then
      local stop = plugin:alterRequestResponseMetaTable(Request, Response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsNewConnection(client)
  for _, plugin in ipairs(self.plugins) do
    if plugin.newConnection then
      client = plugin:newConnection(client)
      if not client then
        return false
      end
    end
  end
  return client
end

function Handler:pluginsNewRequestResponse(request, response)
  for _, plugin in ipairs(self.plugins) do
    if plugin.newRequestResponse then
      local stop = plugin:newRequestResponse(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsBeforeProcess(request, response)
  for _, plugin in ipairs(self.plugins) do
    if plugin.beforeProcess then
      local stop = plugin:beforeProcess(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsAfterProcess(request, response)
  for _, plugin in ipairs(self.plugins) do
    if plugin.afterProcess then
      local stop = plugin:afterProcess(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsProcessFile(request, response, filename)
  for _, plugin in ipairs(self.plugins) do
    if plugin.processFile then
      local stop = plugin:processFile(request, response, filename)

      if stop then
        return stop
      end
    end
  end
end

function Handler:processBodyData(data, stayOpen, response)
  local localData = data

  for _, plugin in ipairs(self.plugins or {}) do
    if plugin.processBodyData then
      localData = plugin:processBodyData(
        localData,
        stayOpen,
        response.request,
        response
      )
    end
  end

  return localData
end

function Handler:processRequest(port, client, server)
  client = self:pluginsNewConnection(client)
  if not client then
    return false
  end

  local request = Request:new(port, client, server, self)
  local response = request.response

  local method = request:method()
  if not method then
    client:close()
    return
  end

  local stop = self:pluginsNewRequestResponse(request, response)
  if stop then
    return
  end

  if self.callback then
    response:statusCode(200)
    response.headers = {}
    response:addHeader('Content-Type', 'text/html')

    stop = self.callback(request, response)
    if stop then
      return
    end
  end

  if not response.closed then
    pcall(response.writeDefaultErrorMessage, response, 404)
  end
end


return Handler
