-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local pegasus = require 'pegasus'

local server = pegasus:new({
  port = '9090',
})

local printTable = function(table)
  for k, v in pairs(table) do
    print(k, '=', v)
  end
end

server:start(function (req, res)
  printTable(req['querystring'])
  res:addHeader('Content-Type', 'text/html'):write('hello pegasus world!')

  -- return a truthy value to indicate the request was handled, no further handling needed
  return res:close()
end)
