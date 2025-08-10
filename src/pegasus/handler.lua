--- Module `pegasus.handler`
--
-- Internal orchestrator that wires the server socket to request/response
-- objects and drives the plugin pipeline.
--
-- Lifecycle for each connection/request:
-- 1. `pluginsNewConnection(client)` can wrap/replace or reject the client
-- 2. Request/Response objects are created
-- 3. `pluginsNewRequestResponse(request, response)` runs
-- 4. `pluginsBeforeProcess(request, response)` runs
-- 5. User `callback(request, response)` is invoked
-- 6. `pluginsAfterProcess(request, response)` runs
-- 7. If response not closed, a default 404 is written
--
-- Plugins may also:
-- - modify Request/Response metatables via `alterRequestResponseMetaTable`
-- - intercept file processing via `processFile`
-- - filter/transform streamed body via `processBodyData`
--
-- Minimal plugin example:
-- ```lua
-- local MyPlugin = {}
-- function MyPlugin:new()
--   return setmetatable({}, { __index = self })
-- end
-- function MyPlugin:beforeProcess(req, res)
--   res:addHeader('X-Powered-By', 'Pegasus')
-- end
-- return MyPlugin
-- ```
--
-- @module pegasus.handler

local Request = require 'pegasus.request'
local Response = require 'pegasus.response'
local Files = require 'pegasus.plugins.files'

--- The request/response handler and plugin runner.
--
-- Fields:
-- - `log`: logger used by the server and plugins
-- - `callback`: user callback `function(request, response)`
-- - `plugins`: array of plugin instances
--
-- @type Handler
---@class Handler
---@field log table
---@field callback fun(request: table, response: table)|nil
---@field plugins table
local Handler = {}
Handler.__index = Handler

--- Construct a `Handler`.
--
-- When `location` is a non-empty string, automatically enables the `files`
-- plugin to serve static files from that directory (default index `/index.html`).
--
-- @tparam function callback user function(request, response)
-- @tparam string location base directory for static files (optional)
-- @tparam table plugins list of plugin instances (optional)
-- @tparam table logger logger instance (optional)
-- @treturn Handler handler
---@param callback fun(request: table, response: table)|nil
---@param location string|nil
---@param plugins table|nil
---@param logger table|nil
---@return Handler
function Handler:new(callback, location, plugins, logger)
  local handler = {}
  handler.log = logger or require('pegasus.log')
  handler.callback = callback
  handler.plugins = plugins or {}

  if location ~= '' then
    handler.plugins[#handler.plugins+1] = Files:new {
      location = location,
      default = "/index.html",
    }
    handler.log:debug('Handler created, location: %s', location)
  else
    handler.log:debug('Handler created, without location')
  end

  local result = setmetatable(handler, self)
  result:pluginsAlterRequestResponseMetatable()

  return result
end

--- Allow plugins to alter `Request`/`Response` metatables before use.
-- Stops early if a plugin returns a truthy value.
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

--- Run `newConnection` hook across plugins.
-- A plugin may wrap or replace the client, or return falsy to abort.
-- @tparam table client accepted client socket
-- @treturn table|false client or false to stop
---@param client table
---@return table|false
function Handler:pluginsNewConnection(client)
  for _, plugin in ipairs(self.plugins) do
    if plugin.newConnection then
      client = plugin:newConnection(client, self)
      if not client then
        return false
      end
    end
  end
  return client
end

--- Run `newRequestResponse` hook across plugins.
-- Stops early if a plugin returns a truthy value.
-- @tparam table request
-- @tparam table response
-- @treturn any stop value if any plugin aborts
---@param request table
---@param response table
---@return any
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

--- Run `beforeProcess` hook across plugins.
-- Stops early if a plugin returns a truthy value.
-- @tparam table request
-- @tparam table response
-- @treturn any stop value if any plugin aborts
---@param request table
---@param response table
---@return any
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

--- Run `afterProcess` hook across plugins.
-- Stops early if a plugin returns a truthy value.
-- @tparam table request
-- @tparam table response
-- @treturn any stop value if any plugin aborts
---@param request table
---@param response table
---@return any
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

--- Run `processFile` hook across plugins for a given filename.
-- Stops early if a plugin returns a truthy value.
-- @tparam table request
-- @tparam table response
-- @tparam string filename
-- @treturn any stop value if any plugin aborts
---@param request table
---@param response table
---@param filename string
---@return any
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

--- Run the body data through plugins' `processBodyData` filters.
-- Each plugin receives `(data, stayOpen, request, response)` and returns the
-- (possibly) transformed data. The result of one plugin is passed to the next.
-- @tparam string data body chunk (may be empty string)
-- @tparam boolean stayOpen whether the connection stays open (chunked)
-- @tparam table response associated response
-- @treturn string transformed data
---@param data string
---@param stayOpen boolean
---@param response table
---@return string
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

--- Process a single client by creating `Request`/`Response` and running pipeline.
-- If the callback does not close the response, a default 404 page is sent.
--
-- @tparam string|number port server port
-- @tparam table client accepted client socket
-- @tparam table server listening server socket
-- @treturn[1] boolean|nil false when connection was rejected by a plugin
-- @treturn[2] nil normal completion
---@param port string|integer
---@param client table
---@param server table
---@return boolean|nil
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
