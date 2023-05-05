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
-- local TLS = require 'pegasus.plugins.tls'

local server = Pegasus:new({
  port = '9090',
  location = '/example/root/',
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
      prefix = "downloads",
      stripPrefix = true,
    },

    Compress:new(),
  }
})

server:start(function(req)
  local data = req:post()

  if data then
    print(data['name'])
    print(data['age'])
  end
end)
