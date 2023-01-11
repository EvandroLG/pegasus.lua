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

local hdlr = Handler:new(function (req, rep)
    --rep.writeHead(200).finish('hello pegasus world!')
  end, '/example/root/')


-- Create http server
local http_server_sock = assert(socket.bind('*', 9090))
local http_ip, http_port = http_server_sock:getsockname()
copas.addserver(http_server_sock, copas.handler(function(http_client_sock)
    hdlr:processRequest(http_port, http_client_sock, http_server_sock)
  end))
print('Pegasus is up on ' .. http_ip .. ":" .. http_port)


-- Create https server
local sslparams = {
   mode = "server",
   protocol = "any",
   key = "./example/serverAkey.pem",
   certificate = "./example/serverA.pem",
   cafile = "./example/rootA.pem",
   verify = {"none"},
   options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"},
}
local https_server_sock = assert(socket.bind('*', 443))
local https_ip, https_port = https_server_sock:getsockname()
copas.addserver(https_server_sock, copas.handler(function(https_client_sock)
    hdlr:processRequest(https_port, https_client_sock, https_server_sock)
  end, sslparams))
print('Pegasus (https) is up on ' .. https_ip .. ":" .. https_port)

-- Start
copas.loop()
