--- The Pegasus server main entry point.
--
-- Minimal, embeddable HTTP server with a simple plugin system.
--
-- Notes:
--
-- - If [LuaLogging](https://keplerproject.github.io/lualogging/) is available, it will be auto-detected and used for logging.
-- - Common plugins include `files`, `router`, `compress`, `downloads`, and `tls`.
-- - See `pegasus.handler` for the request/response lifecycle and plugin hooks.
--
-- Example:
--
--     local Pegasus = require 'pegasus'
--     local server = Pegasus:new{ host = '127.0.0.1', port = '8080' }
--     server:start(function(request, response)
--       response:statusCode(200)
--       response:addHeader('Content-Type', 'text/plain')
--       response:write('Hello, world!')
--     end)
-- @classmod pegasus

local socket = require 'socket'
local Handler = require 'pegasus.handler'

-- require lualogging if available, "pegasus.log" will automatically pick it up
pcall(require, 'logging')

--- The Pegasus HTTP server class.
-- Instances are created via `Pegasus:new(params)`.
local Pegasus = {}
Pegasus.__index = Pegasus

--- Create a new Pegasus server instance.
-- @tparam[opt] table params configuration table
-- @tparam[opt='*'] string params.host bind address
-- @tparam[opt=9090] string|number params.port bind port
-- @tparam[opt=""] string params.location base directory used by some plugins
-- @tparam[opt={}] table params.plugins` list of plugins to be applied
-- @tparam[opt=1] number params.timeout client socket timeout in seconds
-- @tparam[opt] logger params.logger a LuaLogging compatible logger object. Defaults to module `pegasus.log`.
-- @return Pegasus server
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
-- Starts the server and handles incoming connections. The provided callback is invoked once per incoming HTTP request.
-- Errors during `socket.bind` will raise; accept errors are logged and the loop continues.
--
-- @tparam function callback using signature `stop_further_processing = function(request, response)`
-- @raise on bind failure
-- @usage
-- server:start(function(request, response)
--   -- inspect `request` (method, path, headers, body, query, etc.)
--   -- then write a response
--   response:statusCode(200)
--   response:addHeader('Content-Type', 'text/plain')
--   response:write('OK')
-- end)
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
