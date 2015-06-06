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

local hdlr = Handler:new(function (req, rep)
    --rep.writeHead(200).finish('hello pegasus world!')
  end, '/root/')


-- Create http server
local server = assert(socket.bind('*', 9090))
local ip, port = server:getsockname()
copas.addserver(server, copas.handler(function(skt)
    hdlr:processRequest(skt)
  end))
print('Pegasus is up on ' .. ip .. ":".. port)


-- Create https server
sslparams = {
   mode = "server",
   protocol = "tlsv1",
   key = "./serverAkey.pem",
   certificate = "./serverA.pem",
   cafile = "./rootA.pem",
   verify = {"peer"},
   options = {"all", "no_sslv2"},
}
local server = assert(socket.bind('*', 443))
local ip, port = server:getsockname()
copas.addserver(server, copas.handler(function(skt)
    hdlr:processRequest(skt)
  end, sslparams))
print('Pegasus (https) is up on ' .. ip .. ":".. port)

-- Start
copas.loop()
