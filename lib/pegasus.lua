local socket = require 'socket'
local Request = require 'lib/request'
local Response = require 'lib/response'


local Pegasus = {}

function Pegasus:new(port)
  self.port = port or '9090'
  return self
end

function Pegasus:start(callback)
  local server = assert(socket.bind("*", self.port))
  local ip, port = server:getsockname()
  print("Pegasus is up on port " .. self.port)
  local was_called = false

  while 1 do
    local client = server:accept()

    client:settimeout(1, 'b')

    if not was_called then
      self:processRequest(client, callback)
      was_called = true
    else
      self:processRequest(client)
    end

    client:close()
  end
end

function Pegasus:processRequest(client, callback)
  local request = Request:new(client)
  local response =  Response:new(client)
  local method = request:method()

  if method == 'GET' then
    self:GET(request, response, callback)
  elseif method == 'POST' then
    self:POST(client, request, response)
  end

  client:send(response.body)
end

function Pegasus:GET(request, response, callback)
  response:processes(request, response)

  if callback then
    callback(request, response)
  end
end

function Pegasus:POST(client, request, response)
  print('POST')
  print(request:post()['name']])
  -- print('body=' .. request:body())
  -- local data, err, partial = client:receive(1000)
  -- local body = ''

  -- if err =='timeout' then
  --     err = nil
  --     data = partial
  -- end

  -- while err == null and data ~= null  do
  --   body = body .. '\n' .. data
  
  --   data, err, partial = client:receive(1000)
  --   print('here?')

  --   if err == 'timeout' then
  --     -- print('partial='..partial)
  --     -- print('timeout')
  --     body = body .. '\n' .. partial
  --     break
  --    end
  -- end

  -- print(body)
  -- print(client:receive())
  -- response:processes(request)
end

return Pegasus
