local function normalize(P)
  P = string.gsub(P ,'\\',        '/')
  P = string.gsub(P, '^/*',       '/')
  P = string.gsub(P, '(/%.%.?)$', '%1/')
  P = string.gsub(P, '/%./',      '/')
  P = string.gsub(P, '/+',        '/')

  while true do
    local first, last = string.find(P, '/[^/]+/%.%./')
    if not first then break end
    P = string.sub(P, 1, first) .. string.sub(P, last + 1)
  end

  while true do
    local n
    P, n = string.gsub(P, '^/%.%.?/', '/')
    if n == 0 then break end
  end

  while true do
    local n
    P, n = string.gsub(P, '/%.%.?$', '/')
    if n == 0 then break end
  end

  return P
end

local Request = {}
Request.__index = Request
Request.PATTERN_METHOD = '^(.-)%s'
Request.PATTERN_PATH = '(%S+)%s*'
Request.PATTERN_PROTOCOL = '(HTTP%/%d%.%d)'
Request.PATTERN_REQUEST = (Request.PATTERN_METHOD ..
Request.PATTERN_PATH ..Request.PATTERN_PROTOCOL)
Request.PATTERN_QUERY_STRING = '([^=]*)=([^&]*)&?'
Request.PATTERN_HEADER = '([%w-]+): ([%w %p]+=?)'

function Request:new(port, client)
  local obj = {}
  obj.client = client
  obj.port = port
  obj.ip = client:getpeername()
  obj.querystring = {}
  obj.firstLine = nil
  obj._method = nil
  obj._path = nil
  obj._params = {}
  obj._headers_parsed = false
  obj._headers = {}
  obj._form = {}
  obj._is_valid = false
  obj._body = ''
  obj._content_done = 0

  return setmetatable(obj, self)
end

function Request:parseFirstLine()
  if (self.firstLine ~= nil) then
    return
  end

  local status, partial
  self.firstLine, status, partial = self.client:receive()

  if (self.firstLine == nil or status == 'timeout' or partial == '' or status == 'closed') then
    return
  end

  -- Parse firstline http: METHOD PATH PROTOCOL,
  -- GET Makefile HTTP/1.1
  local method, path, protocol = string.match(self.firstLine, Request.PATTERN_REQUEST)

  if not method then
    --! @todo close client socket immediately
    return
  end

  print('Request for: ' .. path)

  local filename = ''
  local querystring = ''

  if #path then
    filename, querystring = string.match(path, '^([^#?]+)[#|?]?(.*)')
    filename = normalize(filename)
  end

  self._path = filename
  self._method = method
  self.querystring = self:parseURLEncoded(querystring, {})
end

function Request:parseURLEncoded(value, _table) -- luacheck: ignore self
  --value exists and _table is empty
  if value and next(_table) == nil then
    for k, v in  string.gmatch(value, Request.PATTERN_QUERY_STRING) do
        _table[k] = v
    end
  end

  return _table
end

function Request:post()
  if self:method() ~= 'POST' then return nil end
  local data = self:receiveBody()
  return self:parseURLEncoded(data, {})
end

function Request:path()
  self:parseFirstLine()
  return self._path
end

function Request:method()
  self:parseFirstLine()
  return self._method
end


function Request:headers()
  if self._headers_parsed then
    return self._headers
  end

  self:parseFirstLine()

  local data = self.client:receive()

  while (data ~= nil) and (data:len() > 0) do
    local key, value = string.match(data, Request.PATTERN_HEADER)

    if key and value then
      self._headers[key] = value
    end

    data = self.client:receive()
  end

  self._headers_parsed = true
  self._content_length = tonumber(self._headers["Content-Length"] or 0)

  return self._headers
end

function Request:receiveBody(size)
  size = size or self._content_length

  -- do we have content?
  if (self._content_length == nil) or (self._content_done >= self._content_length) then
    return false
  end

  -- fetch in chunks
  local fetch = math.min(self._content_length-self._content_done, size)

  local data, err, partial = self.client:receive(fetch)

  if err == 'timeout' then
    data = partial
  end

  self._content_done = self._content_done + #data

  return data
end

return Request
