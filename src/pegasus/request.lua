--- Request object available in callback handlers.
--
-- Parsed HTTP request facade used by your application callback. Instances are
-- created internally by Pegasus and passed to the callback provided to `pegasus:start`,
-- and plugin handlers.
--
-- Fields on the object:
--
-- * `request.client`: the client socket (wrapped by TLS if TLS plugin is used)
-- * `request.server`: the server socket
-- * `response.log`: the logger object, to enable logging from handlers and plugins
-- * `request.port`: the port on which the request was received
-- * `request.ip`: the IP address of the client, if available (not supported by LuaSec)
-- * `request.response`: the related `pegasus.response` object to write the response to
--
-- Quick example:
--
--     server:start(function(req, res)
--       local method = req:method()
--       local path = req:path()
--       local headers = req:headers()
--       local qs = req.querystring -- table of query params
--
--       if method == 'POST' then
--         local form = req:post() -- urlencoded form body, or nil if not POST
--       end
--     end)
-- @classmod pegasus.request
local Response = require 'pegasus.response'

local function normalizePath(path)
  local value = string.gsub(path ,'\\', '/')
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
Request.PATTERN_PATH ..Request.PATTERN_PROTOCOL)
Request.PATTERN_QUERY_STRING = '([^=]*)=([^&]*)&?'
Request.PATTERN_HEADER = '([%w-]+):[ \t]*([%w \t%p]*)'

-- Internal: construct a new Request.
--
-- @tparam string|number port server port
-- @tparam table client accepted client socket
-- @tparam table server listening server socket
-- @tparam table handler internal handler (provides `log` and body processing)
-- @treturn Request request
function Request:new(port, client, server, handler)
  local obj = {}
  obj.client = client
  obj.server = server
  obj.log = handler.log
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
  obj.response = Response:new(client, handler)
  obj.response.request = obj

  return setmetatable(obj, self)
end

-- Internal: parse the request line and query-string on first access.
function Request:parseFirstLine()
  if (self._firstLine ~= nil) then
    return
  end

  local status, partial
  self._firstLine, status, partial = self.client:receive("*l")

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
  self.response:skipBody(method == "HEAD")

  self.log:info('Request for: %s %s', method, path)

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

--- Parse `application/x-www-form-urlencoded` data.
-- Returns a hash table. Duplicate keys are represented as an array of values.
-- @tparam string data
-- @treturn table params
function Request:parseUrlEncoded(data)
  local output = {}

  if data then
    for key, value in  string.gmatch(data, Request.PATTERN_QUERY_STRING) do
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

--- parse POST body as `application/x-www-form-urlencoded`.
-- Returns `nil` if method is not POST.
-- @treturn[1] table parsed form values, see `parseUrlEncoded` for details on the format of this table.
-- @treturn[2] nil when not a POST request
function Request:post()
  if self:method() ~= 'POST' then return nil end
  local data = self:receiveBody()
  return self:parseUrlEncoded(data)
end

--- Request path (normalized), without query-string.
-- @treturn string path
function Request:path()
  self:parseFirstLine()
  return self._path
end

--- HTTP method.
-- @treturn string method
function Request:method()
  self:parseFirstLine()
  return self._method
end

--- Query-string parameters.
-- Returns a hash table. Duplicate keys are represented as an array of values.
-- @treturn table querystring
function Request:query()
  self:parseFirstLine()
  return self.querystring
end

--- Request headers.
-- Returns a case-insensitive table: looking up with any casing works.
-- If a header appears multiple times, the value becomes a table of strings.
-- @treturn table headers
function Request:headers()
  if self._headerParsed then
    return self._headers
  end

  self:parseFirstLine()

  local data = self.client:receive("*l")

  local headers = setmetatable({},{ -- add metatable to do case-insensitive lookup
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

    data = self.client:receive("*l")
  end

  self._headerParsed = true
  self._contentLength = tonumber(headers["content-length"] or 0)
  self._headers = headers

  return headers
end

--- Receive a chunk of the request body.
-- Ensures headers are parsed. Returns `false` when there is no body or it is fully consumed.
-- When a socket timeout happens, any partial data is returned.
-- @tparam[opt] number size preferred chunk size
-- @treturn string|false chunk or false if no more content
function Request:receiveBody(size)
  if not self._headerParsed then
    self:headers()
  end
  local contentLength = self._contentLength
  local contentDone = self._contentDone
  size = size or contentLength

  -- do we have content?
  if (contentLength == nil) or (contentDone >= contentLength) then
    return false
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
