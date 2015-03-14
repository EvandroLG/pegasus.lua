local Pegasus = require '../pegasus/pegasus'

local server = Pegasus:new('9090')

server:start(function (req, rep)
  --rep.writeHead(200).finish('hello pegasus world!')
end)
