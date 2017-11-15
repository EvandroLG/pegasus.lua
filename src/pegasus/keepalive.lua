-- This plugin works with coroutine based sokets like copas.
-- If request support keep-alive connection plugin uses `receive`
-- method and wait next request. So do not use it with native
-- LuaSocket module.

--! @todo implement more efficient data structure
local Fifo = {} do
Fifo.__index = Fifo

function Fifo:new()
  local o = setmetatable({
    _by_idx = {};
  }, self)

  return o
end

function Fifo:push(v)
  self._by_idx[#self._by_idx + 1] = v
end

function Fifo:pop()
  return table.remove(self._by_idx, 1)
end

function Fifo:remove_value(v)
  for i = 1, #self._by_idx do
    if self._by_idx[i] == v then
      return table.remove(self._by_idx, i)
    end
  end
end

function Fifo:size()
  return #self._by_idx
end

end

local KeepAlive = {} do
KeepAlive.__index = KeepAlive

-- NOTE. `response:keep_alive` calls also before send response
-- to be able set `Connection` header. So there no sense test socket here.
local function build_keep_alive(keepalive)
  return function(response)
    local request = response.request

    local requests_count = request.keepalive_requests
    if requests_count >= keepalive._requests then return false end

    return request:support_keep_alive()
  end
end

local function socket_close(s)
  return s:close()
end

function KeepAlive:new(opt)
  local o = setmetatable({
    _fifo = Fifo:new();
    -- how long connection wait next request
    _wait_timeout = opt and opt.wait_timeout or 60;
    -- timeout to preceed next request
    _req_timeout = opt and opt.request_timeout or 5;
    -- max requests per connection
    _requests = opt and opt.requests or 10;
    -- max connection count
    _connections = opt and opt.connections or 10;
    -- function to test either socket is alive
    _socket_test = opt and opt.socket_test;
    -- function to interupt socket from other thread
    _socket_close = opt and opt.socket_close or socket_close;
  }, self)

  o._response_keep_alive = build_keep_alive(o)

  return o
end

function KeepAlive:newRequestResponse(request, response)
  response.keep_alive = self._response_keep_alive
  request.keepalive_requests = request.keepalive_requests or 0 -- counter of requests
end

function KeepAlive:afterProcess(request, response)
  request.keepalive_requests = request.keepalive_requests + 1

  -- if we do not send response or send `Connection: close` then we can not reuse connection
  if (not response.headersSended) or (response.headers.Connection == 'close') then
    return
  end

  -- if request does not support keep alive
  if not response:keep_alive() then
    return
  end

  if self._socket_test and not self._socket_test(request.client) then
    return
  end

  self._fifo:push(request:reset())

  if self._fifo:size() > self._connections then
    local req = self._fifo:pop()
    -- interupt some other connection
    self._socket_close(req.client)
  end

  request.client:settimeout(self._wait_timeout)

  local method = request:method()
  self._fifo:remove_value(request)

  if not method then
    -- timeout or connection closed
    return
  end

  request.client:settimeout(self._req_timeout)

  -- return request to reuse it
  return request
end

end

return KeepAlive