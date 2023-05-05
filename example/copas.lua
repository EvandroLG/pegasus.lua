-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path


-- Example that uses Copas as a socket scheduler, allowing multiple
-- servers to work in parallel.
-- For this example to work with the https version, you need LuaSec
-- to be installed, and you need to generate the test certificates from
-- its examples. Copy the 'A' certificates into this example directory
-- to make it work.
local Handler = require 'pegasus.handler'
local copas = require('copas')
local socket = require('socket')
local Downloads = require 'pegasus.plugins.downloads'

--- Creates a new server within the Copas scheduler.
-- @tparam table opts options table.
-- @tparam[opt='*'] string opts.interface the interface to listen on, or '*' for all.
-- @tparam string          opts.port the port number to listen on.
-- @tparam[opt] table      opts.sslparams the tls based parameters, see the Copas documentation.
--                         If not provided, then the connection will be accepted as a plain one.
-- @tparam[opt] table      opts.plugins the plugins to use
-- @tparam[opt] function   opts.handler the callback function to handle requests
-- @tparam[opt] string     opts.location the file-path from where to server files
-- @return the server-socket on success, or nil+err on failure
local function newPegasusServer(opts)
  opts = opts or {}
  assert(opts.location or opts.callback, "either 'location' or 'callback' must be provided")
  assert(opts.port, "option 'port' must be provided")

  local server_sock, err = socket.bind(opts.interface or '*', opts.port)
  if not server_sock then
    return nil, "failed to create server socket; ".. tostring(err)
  end

  local server_ip, server_port = server_sock:getsockname()
  if not server_ip then
    return nil, "failed to get server socket name; "..tostring(server_port)
  end

  local hdlr = Handler:new(opts.callback, opts.location, opts.plugins)

  copas.addserver(server_sock, copas.handler(function(client_sock)
    hdlr:processRequest(server_port, client_sock)
  end, opts.sslparams))

  io.stderr:write('Pegasus is up on ' .. (opts.sslparams and "https" or "http") .. "://" .. server_ip .. ":" .. server_port .. "/\n")
  return server_sock
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
  location = '/example/root/',
  callback = nil,
  plugins = {
    Downloads:new {
      prefix = "downloads",
      stripPrefix = true,
    },
  },
})

-- Start
copas.loop()
