package.path = package.path .. ';../?.lua'
local Pegasus = require 'lib/pegasus'

local server = Pegasus:new('9090')

server:start(function (req, rep)
  print('path = ' .. req:path())
  print('method = ' .. req:method())
  print('body = ' .. rep:body
end)