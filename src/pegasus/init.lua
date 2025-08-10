--- Module `pegasus`
--
-- Minimal, embeddable HTTP server with a simple plugin system.
--
-- Basic usage:
-- ```lua
-- local Pegasus = require 'pegasus'
-- local server = Pegasus:new{ host = '127.0.0.1', port = '8080' }
-- server:start(function(request, response)
--   response:statusCode(200)
--   response:addHeader('Content-Type', 'text/plain')
--   response:write('Hello, world!')
-- end)
-- ```
--
-- Notes:
-- - If [LuaLogging](https://keplerproject.github.io/lualogging/) is available, it will be auto-detected and used for logging.
-- - Common plugins include `files`, `router`, `compress`, `downloads`, and `tls`.
-- - `start` runs a blocking accept loop; run in a dedicated OS thread/process if you need concurrency.
--
-- @module pegasus

local socket = require 'socket'
local Handler = require 'pegasus.handler'

-- require lualogging if available, "pegasus.log" will automatically pick it up
pcall(require, 'logging')

--- The Pegasus HTTP server class.
-- Instances are created via `Pegasus:new(params)`.
--
-- Fields (defaults in parentheses):
-- - `host` ("*") bind address, e.g. "127.0.0.1" or "::".
-- - `port` ("9090") bind port.
-- - `location` ("") base directory for static files/plugins that use the filesystem.
-- - `plugins` ({}) array/table of plugin callables or plugin configurations.
-- - `timeout` (1) client socket timeout (seconds, blocking operations).
-- - `log` (auto) logger compatible with `pegasus.log` API. Defaults to `require('pegasus.log')` and integrates with LuaLogging when present.
--
-- @type Pegasus
-- @tfield string host
-- @tfield string|number port
-- @tfield string location
-- @tfield table plugins
-- @tfield number timeout
-- @tfield table log
---@class Pegasus
---@field host string
---@field port string|integer
---@field location string
---@field plugins table
---@field timeout number
---@field log table
local Pegasus = {}
Pegasus.__index = Pegasus

--- Create a new Pegasus server instance.
--
-- Parameters table accepts:
-- - `host`: bind address (default "*").
-- - `port`: bind port (default "9090").
-- - `location`: base directory used by some plugins (default "").
-- - `plugins`: list/table of plugins to be applied (default {}).
-- - `timeout`: client socket timeout in seconds (default 1).
-- - `log`: logger instance; if omitted, `pegasus.log` is used (integrates with LuaLogging when available).
--
-- @tparam[opt] table params configuration table
-- @treturn Pegasus server
---@param params table|nil
---@return Pegasus
function Pegasus:new(params)
  params = params or {}
  local server = {}

  server.host = params.host or '*'
  server.port = params.port or '9090'
  server.location = params.location or ''
  server.plugins = params.plugins or {}
  server.timeout = params.timeout or 1
  server.log = params.log or require('pegasus.log')

  return setmetatable(server, self)
end

--- Start the server accept loop (blocking).
--
-- The provided callback is invoked once per incoming HTTP request.
--
-- Example:
-- ```lua
-- server:start(function(request, response)
--   -- inspect `request` (method, path, headers, body, query, etc.)
--   -- then write a response
--   response:statusCode(200)
--   response:addHeader('Content-Type', 'text/plain')
--   response:write('OK')
-- end)
-- ```
--
-- Errors during `socket.bind` will raise; accept errors are logged and the loop continues.
--
-- @tparam function callback function(request, response)
-- @raise on bind failure
---@param callback fun(request: table, response: table)
function Pegasus:start(callback)
  local handler = Handler:new(callback, self.location, self.plugins, self.log)
  local server = assert(socket.bind(self.host, self.port))
  local ip, port = server:getsockname()

  print('Pegasus is up on ' .. ip .. ":".. port) -- needed in case no LuaLogging is available
  handler.log:info('Pegasus is up on %s:%s', ip, port)

  while 1 do
    local client, errmsg = server:accept()

    if client then
      client:settimeout(self.timeout, 'b')
      handler:processRequest(self.port, client, server)
    else
      handler.log:error('Failed to accept connection: %s', errmsg)
    end
  end
end

return Pegasus
