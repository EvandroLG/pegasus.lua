package.path = package.path .. ';../?.lua'
local HTTPServer = require 'lib/webserver'


httpServer = HTTPServer:new('9090')

httpServer:start(function (req, rep)
  print(req:params()['name'])
end)