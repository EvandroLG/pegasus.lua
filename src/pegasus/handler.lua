local Request = require 'pegasus.request'
local Response = require 'pegasus.response'
local mimetypes = require 'mimetypes'
local lfs = require 'lfs'

local function ternary(condition, t, f)
  if condition then return t else return f end
end

local Handler = {}
Handler.__index = Handler

function Handler:new(callback, location, plugins)
  local handler = {}
  handler.callback = callback
  handler.location = location or ''
  handler.plugins = plugins or {}

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
      localData = plugin:processBodyData(localData, stayOpen,
                   response.request,  response)
    end
  end

  return localData
end

function Handler:requestDone(request, response)
  local stop = self:pluginsAfterProcess(request, response)

  if stop then
    -- coroutine based keep-alive
    if stop == request then return self:internalProcessRequest(request) end
    return
  end

  request.client:close()
end

-- this function can be called multiple times for single request
-- if server supports keep alive
function Handler:internalProcessRequest(request)
  -- if we get some invalid request just close it
  -- do not try handle or response
  if not request:method() then
    request.client:close()
    return
  end

  local response = Response:new(self, request)

  local stop = self:pluginsNewRequestResponse(request, response)

  if stop then
    return self:requestDone(request, response)
  end

  if request:path() and self.location ~= '' then
    local path = ternary(request:path() == '/' or request:path() == '',
                 'index.html', request:path())
    local filename = '.' .. self.location .. path

    if not lfs.attributes(filename) then
      response:statusCode(404)
    end

    stop = self:pluginsProcessFile(request, response, filename)

    if stop then
      return self:requestDone(request, response)
    end

    local file = io.open(filename, 'rb')

    if file then
      response:writeFile(file, mimetypes.guess(filename or '') or 'text/html')
    else
      response:statusCode(404)
    end
  end

  if self.callback then
    -- response:statusCode(200)
    -- response.headers = {}
    -- response:addHeader('Content-Type', 'text/html')
    self.callback(request, response)
  end

  -- if callback did not send any then we have to send some response
  if not response.headers_sended then
    if not response.status then
      response:statusCode(500)
    end
    response:writeDefaultErrorMessage(response.status)
  end

  return self:requestDone(request, response)
end

-- this function called for new connection
function Handler:processRequest(port, client)
  local request = Request:new(port, client)

  return self:internalProcessRequest(request)
end

return Handler
