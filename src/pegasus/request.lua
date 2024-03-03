local function normalizePath(path)
  local value = string.gsub(path, '\\', '/')
  value = string.gsub(value, '^/*', '/')
  value = string.gsub(value, '(/%.%.?)$', '%1/')
  value = string.gsub(value, '/%./', '/')
  value = string.gsub(value, '/+', '/')

  while true do
    local first, last = string.find(value, '/[^/]+/%.%./')
    if not first then break end
    value = string.sub(value, 1, first) .. string.sub(value, last + 1)
  end

  while true do
    local n
    value, n = string.gsub(value, '^/%.%.?/', '/')
    if n == 0 then break end
  end

  while true do
    local n
    value, n = string.gsub(value, '/%.%.?$', '/')
    if n == 0 then break end
  end

  return value
end

local Request = {}
Request.__index = Request
Request.PATTERN_METHOD = '^(.-)%s'
Request.PATTERN_PATH = '(%S+)%s*'
Request.PATTERN_PROTOCOL = '(HTTP%/%d%.%d)'
Request.PATTERN_REQUEST = (Request.PATTERN_METHOD ..
  Request.PATTERN_PATH .. Request.PATTERN_PROTOCOL)
Request.PATTERN_QUERY_STRING = '([^=]*)=([^&]*)&?'
Request.PATTERN_HEADER = '([%w-]+):[ \t]*([%w \t%p]*)'

-- Create a new request
-- @param port {number}
-- @param client {table}
-- @param server {table}
-- @return {table}
function Request:new(port, client, server)
  local obj = {}
  obj.client = client
  obj.server = server
  obj.port = port
  obj.ip = (client.getpeername or function() end)(client) -- luasec doesn't support this method
  obj.querystring = {}
  obj._firstLine = nil
  obj._method = nil
  obj._path = nil
  obj._params = {}
  obj._headerParsed = false
  obj._headers = {}
  obj._contentDone = 0
  obj._contentLength = nil

  return setmetatable(obj, self)
end

-- Parse the first request line
-- @return {nil}
function Request:parseFirstLine()
  if (self._firstLine ~= nil) then
    return
  end

  local status, partial
  self._firstLine, status, partial = self.client:receive()

  if (self._firstLine == nil or status == 'timeout' or partial == '' or status == 'closed') then
    return
  end

  -- Parse firstline http: METHOD PATH
  -- GET Makefile HTTP/1.1
  local method, path = string.match(self._firstLine, Request.PATTERN_REQUEST)

  if not method then
    self.client:close()
    return
  end

  print('Request for: ' .. path)

  local filename = ''
  local querystring = ''

  if #path then
    filename, querystring = string.match(path, '^([^#?]+)[#|?]?(.*)')
    filename = normalizePath(filename)
  end

  self._path = filename
  self._method = method
  self.querystring = self:parseUrlEncoded(querystring)
end

-- Parse an encoded URL
-- @param data {string}
-- @return {table}
function Request:parseUrlEncoded(data)
  local output = {}

  if data then
    for key, value in string.gmatch(data, Request.PATTERN_QUERY_STRING) do
      if key and value then
        local v = output[key]
        if not v then
          output[key] = value
        elseif type(v) == "string" then
          output[key] = { v, value }
        else -- v is a table
          v[#v + 1] = value
        end
      end
    end
  end

  return output
end

-- Make a POST request
-- @return {table}
function Request:post()
  if self:method() ~= 'POST' then return nil end
  local data = self:receiveBody()
  return self:parseUrlEncoded(data)
end

-- Get the request path
-- @return {string}
function Request:path()
  self:parseFirstLine()
  return self._path
end

-- Get the request method
-- @return {string}
function Request:method()
  self:parseFirstLine()
  return self._method
end

-- Get the request headers
-- @return {table}
function Request:headers()
  if self._headerParsed then
    return self._headers
  end

  self:parseFirstLine()

  local data = self.client:receive()

  local headers = setmetatable({}, { -- add metatable to do case-insensitive lookup
    __index = function(self, key)
      if type(key) == "string" then
        key = key:lower()
        return rawget(self, key)
      end
    end
  })

  while (data ~= nil) and (data:len() > 0) do
    local key, value = string.match(data, Request.PATTERN_HEADER)

    if key and value then
      key = key:lower()
      value = value:gsub("%s+$", "") -- trim trailing whitespace
      local v = headers[key]
      if not v then
        headers[key] = value
      elseif type(v) == "string" then
        headers[key] = { v, value }
      else -- t == "table", v is a table
        v[#v + 1] = value
      end
    end

    data = self.client:receive()
  end

  self._headerParsed = true
  self._contentLength = tonumber(headers["content-length"] or 0)
  self._headers = headers

  return headers
end

-- Receives the body of the request in chunks
-- @param size {number}
-- @return {string|nil}
function Request:receiveBody(size)
  if not self._headerParsed then
    self:headers()
  end
  local contentLength = self._contentLength
  local contentDone = self._contentDone
  size = size or contentLength

  -- do we have content?
  if (contentLength == nil) or (contentDone >= contentLength) then
    return nil
  end

  -- fetch in chunks
  local fetch = math.min(contentLength - contentDone, size)
  local data, err, partial = self.client:receive(fetch)

  if err == 'timeout' then
    data = partial
  end

  self._contentDone = contentDone + #data

  return data
end

return Request
