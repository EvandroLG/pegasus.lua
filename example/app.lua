-- setup path to find the project source files of Pegasus
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

-- For this example to work with the https version, you need LuaSec
-- to be installed, and you need to generate the test certificates from
-- its examples. Copy the 'A' certificates into this example directory
-- to make it work.
-- Then uncomment the TLS plugin section below.
-- Additionally you need lua-cjson to be installed.

local Pegasus = require 'pegasus'
local Compress = require 'pegasus.plugins.compress'
local Downloads = require 'pegasus.plugins.downloads'
local Files = require 'pegasus.plugins.files'
local Router = require 'pegasus.plugins.router'
local json = require 'cjson.safe'
-- local TLS = require 'pegasus.plugins.tls'


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
        print("served " .. req.pathParameters.name .. "'s data")
        return stop
      end,
    }
  }
end


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

    Router:new {
      prefix = "/api/1v0/",
      routes = routes,
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
