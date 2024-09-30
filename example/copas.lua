-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path


-- Example that uses Copas as a socket scheduler, allowing multiple
-- servers to work in parallel.
-- For this example to work with the https version, you need LuaSec
-- to be installed, and you need to generate the test certificates from
-- its examples. Copy the 'A' certificates into this example directory
-- to make it work.
-- Additionally you need lua-cjson to be installed.

-- require lualogging if available, "pegasus.log" will automatically pick it up
pcall(require, 'logging')

local Handler = require 'pegasus.handler'
local copas = require('copas')
local socket = require('socket')
local Downloads = require 'pegasus.plugins.downloads'
local Files = require 'pegasus.plugins.files'
local Router = require 'pegasus.plugins.router'
local Compress = require 'pegasus.plugins.compress'
local json = require 'cjson.safe'


--- Creates a new server within the Copas scheduler.
-- @tparam table opts options table.
-- @tparam[opt='*'] string opts.interface the interface to listen on, or '*' for all.
-- @tparam string          opts.port the port number to listen on.
-- @tparam[opt] table      opts.sslparams the tls based parameters, see the Copas documentation.
--                         If not provided, then the connection will be accepted as a plain one.
-- @tparam[opt] table      opts.plugins the plugins to use
-- @tparam[opt] function   opts.callback the callback function to handle requests
-- @tparam[opt] string     opts.location the file-path from where to serve files
-- @tparam[opt] logger     opts.log the LuaLogging logger to use (defaults to LuaLogging default logger)
-- @return the server-socket on success, or nil+err on failure
local function newPegasusServer(opts)
  opts = opts or {}
  assert(opts.port, "option 'port' must be provided")

  local server_sock, err = socket.bind(opts.interface or '*', opts.port)
  if not server_sock then
    return nil, "failed to create server socket; ".. tostring(err)
  end

  local server_ip, server_port = server_sock:getsockname()
  if not server_ip then
    return nil, "failed to get server socket name; "..tostring(server_port)
  else
    if server_ip == "0.0.0.0" then
      server_ip = "localhost"
    end
  end

  local hdlr = Handler:new(opts.callback, opts.location, opts.plugins, opts.log)

  copas.addserver(server_sock, copas.handler(function(client_sock)
    hdlr:processRequest(server_port, client_sock)
  end, opts.sslparams))

  hdlr.log:info('Pegasus is up on %s://%s:%s', opts.sslparams and "https" or "http", server_ip, server_port)
  return server_sock
end


-- example data for the "router" plugin
local routes do
  local testData = {
    Jane = { firstName = "Jane", lastName = "Doe", age = 25 },
    John = { firstName = "John", lastName = "Doe", age = 30 },
  }

  routes = {
    -- router-level preFunction runs before the method prefunction and callback
    preFunction = function(req, resp)
      local stop = false
      local headers = req:headers()
      local accept = (headers.accept or "*/*"):lower()
      if not accept:find("application/json", 1, true) and
         not accept:find("application/*", 1, true) and
         not accept:find("*/*", 1, true) then

        resp:writeDefaultErrorMessage(406, "This API only produces 'application/json'")
        stop = true
      end
      return stop
    end,

    ["/people"] = {
      GET = function(req, resp)
        resp:statusCode(200)
        resp:addHeader("Content-Type", "application/json")
        resp:write(json.encode(testData))
      end,
    },

    ["/people/{name}"] = {
      -- path-level preFunction runs before the actual method callback
      preFunction = function(req, resp)
        local stop = false
        local name = req.pathParameters.name
        if not testData[name] then
          local err = ("'%s' is an unknown person"):format(name)
          req.log:error(err)
          resp:writeDefaultErrorMessage(404, err)
          stop = true
        end
        return stop
      end,

      -- callback per method
      GET = function(req, resp)
        resp:statusCode(200)
        resp:addHeader("Content-Type", "application/json")
        resp:write(json.encode(testData[req.pathParameters.name]))
      end,

      -- postFunction runs after the actual method callback
      postFunction = function(req, resp)
        local stop = false
        req.log:debug("served %s's data", req.pathParameters.name)
        return stop
      end,
    }
  }
end



-- Create http server
assert(newPegasusServer{
  interface = "*",
  port = "9090",
  sslparams = nil,
  location = nil,
  callback = function(req, resp) -- just redirecting to the https one
    local host = (req:headers()["Host"] or ""):match("^([^:]+)")
    resp:redirect("https://" .. host .. ":9091" .. req:path())
  end,
  plugins = {},
})


-- Create https server
assert(newPegasusServer{
  interface = "*",
  port = "9091",
  sslparams = {  -- the tls specific configuration
    wrap = {
      mode = "server",
      protocol = "any",
      key = "./example/serverAkey.pem",
      certificate = "./example/serverA.pem",
      cafile = "./example/rootA.pem",
      verify = {"none"},
      options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"},
    },
    sni = nil,
  },

  plugins = {
    Downloads:new {
      location = '/example/root/',
      prefix = 'downloads',
      stripPrefix = true,
    },

    Files:new {
      location = '/example/root/',
    },

    Router:new {
      prefix = "/api/1v0/",
      routes = routes,
    },

    Compress:new(),
  }
})

-- Start
copas.loop()
