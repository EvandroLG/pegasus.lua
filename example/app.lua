-- setup path to find the project source files of Pegasus
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

-- For this example to work with the https version, you need LuaSec
-- to be installed, and you need to generate the test certificates from
-- its examples. Copy the 'A' certificates into this example directory
-- to make it work.
-- Then uncomment the TLS plugin section below.

local Pegasus = require 'pegasus'
local Compress = require 'pegasus.plugins.compress'
local Downloads = require 'pegasus.plugins.downloads'
local Files = require 'pegasus.plugins.files'
-- local TLS = require 'pegasus.plugins.tls'

local server = Pegasus:new({
  port = '9090',
  plugins = {
    -- TLS:new {  -- the tls specific configuration
    --   wrap = {
    --     mode = "server",
    --     protocol = "any",
    --     key = "./example/serverAkey.pem",
    --     certificate = "./example/serverA.pem",
    --     cafile = "./example/rootA.pem",
    --     verify = {"none"},
    --     options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"},
    --   },
    --   sni = nil,
    -- },

    Downloads:new {
      location = '/example/root/',
      prefix = 'downloads',
      stripPrefix = true,
    },

    Files:new {
      location = '/example/root/',
    },

    Compress:new(),
  }
})

server:start(function(req, resp)
  local stop = false

  local path = req:path()
  if req:method() ~= "POST" or path ~= "/index.html" then
    return stop
  end

  local data = req:post()
  if data then
    print("Name: ", data.name)
    print("Age: ", data.age)
  end
  stop = not not resp:writeFile("./example/root" .. path)
  return stop
end)
