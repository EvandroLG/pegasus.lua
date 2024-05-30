-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'

local server = Pegasus:new()

server:start(function (req, res)
  res:addHeader('Content-Type', 'text/html'):write('hello pegasus world!')

  -- return a truthy value to indicate the request was handled, no further handling needed
  return res:close()
end)
