local Request = {}

function Request:new(client)
  local newObj = {}
  self.__index = self
  newObj.client = client
  newObj.firstLine = nil
  newObj._method = nil
  newObj._path = nil
  newObj._params = {}
  newObj._headers_parsed = false
  newObj._headers = {}
  newObj._form = {}
  newObj._is_valid = false
  newObj._body = ''
  newObj._content_done = 0

  return setmetatable(newObj, self)
end

Request.PATTERN_METHOD = '^(.*)%s'
Request.PATTERN_PATH = '(.*)%s'
Request.PATTERN_PROTOCOL = '(HTTP%/[0-9]%.[0-9])'
Request.PATTERN_REQUEST = (Request.PATTERN_METHOD ..
Request.PATTERN_PATH ..Request.PATTERN_PROTOCOL)

function Request:parseFirstLine()
  if (self.firstLine ~= nil) then
    return
  end

  local status, partial
  self.firstLine, status, partial = self.client:receive()

  if (self.firstLine == nil and status == 'timeout' and partial == '' or status == 'closed') then
    return
  end

  -- Parse firstline http: METHOD PATH PROTOCOL,
  -- GET Makefile HTTP/1.1
  local method, path, protocol = string.match(self.firstLine,
                                 Request.PATTERN_REQUEST)
  local filename, querystring = string.match(path, '^([^#?]+)[#|?]?(.*)')

  self._path = filename
  self._query_string = querystring
  self._method = method
end

Request.PATTERN_QUERY_STRING = '([^=]*)=([^&]*)&?'

function Request:parseURLEncoded(value, _table)
  --value exists and _table is empty
  if value and next(_table) == nil then
    for k, v in  string.gmatch(value, Request.PATTERN_QUERY_STRING) do
        _table[k] = v
    end
  end

  return _table
end

function Request:params()
  self:parseFirstLine()
  return self:parseURLEncoded(self._query_string, self._params)
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

Request.PATTERN_HEADER = '([%w-]+): ([%w %p]+=?)'

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
   self:headers()
   local data, _, partial = self.client:receive("*a")
   return data or partial
end

return Request
