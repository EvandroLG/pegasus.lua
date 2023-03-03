local mimetypes = require 'mimetypes'

local function toHex(dec)
  local charset = { '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f' }
  local tmp = {}

  repeat
    table.insert(tmp, 1, charset[dec % 16 + 1])
    dec = math.floor(dec / 16)
  until dec == 0

  return table.concat(tmp)
end

local STATUS_TEXT = setmetatable({
  [100] = 'Continue',
  [101] = 'Switching Protocols',
  [200] = 'OK',
  [201] = 'Created',
  [202] = 'Accepted',
  [203] = 'Non-Authoritative Information',
  [204] = 'No Content',
  [205] = 'Reset Content',
  [206] = 'Partial Content',
  [300] = 'Multiple Choices',
  [301] = 'Moved Permanently',
  [302] = 'Found',
  [303] = 'See Other',
  [304] = 'Not Modified',
  [305] = 'Use Proxy',
  [307] = 'Temporary Redirect',
  [400] = 'Bad Request',
  [401] = 'Unauthorized',
  [402] = 'Payment Required',
  [403] = 'Forbidden',
  [404] = 'Not Found',
  [405] = 'Method Not Allowed',
  [406] = 'Not Acceptable',
  [407] = 'Proxy Authentication Required',
  [408] = 'Request Time-out',
  [409] = 'Conflict',
  [410] = 'Gone',
  [411] = 'Length Required',
  [412] = 'Precondition Failed',
  [413] = 'Request Entity Too Large',
  [414] = 'Request-URI Too Large',
  [415] = 'Unsupported Media Type',
  [416] = 'Requested range not satisfiable',
  [417] = 'Expectation Failed',
  [429] = 'Too Many Requests',
  [500] = 'Internal Server Error',
  [501] = 'Not Implemented',
  [502] = 'Bad Gateway',
  [503] = 'Service Unavailable',
  [504] = 'Gateway Time-out',
  [505] = 'HTTP Version not supported',
}, {
  __index = function(self, statusCode)
    -- if the lookup failed, try coerce to a number and try again
    if type(statusCode) == "string" then
      local result = rawget(self, tonumber(statusCode) or -1)
      if result then
        return result
      end
    end
    error("http status code '"..tostring(statusCode).."' is unknown", 2)
  end,
})

local DEFAULT_ERROR_MESSAGE = [[
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Error response</title>
</head>
<body>
  <h1>Error response</h1>
  <p>Error code: {{ STATUS_CODE }}</p>
  <p>Message: {{ STATUS_TEXT }}</p>
</body>
</html>
]]

local Response = {}
Response.__index = Response

function Response:new(client, writeHandler)
  local newObj = {}
  newObj._headersSended = false
  newObj._templateFirstLine = 'HTTP/1.1 {{ STATUS_CODE }} {{ STATUS_TEXT }}\r\n'
  newObj._headFirstLine = ''
  newObj._headers = {}
  newObj._isClosed = false
  newObj._client = client
  newObj._writeHandler = writeHandler
  newObj.status = 200

  return setmetatable(newObj, self)
end

function Response:addHeader(key, value)
  assert(not self._headersSended, "can't add header, they were already sent")
  self._headers[key] = value
  return self
end

function Response:addHeaders(params)
  for key, value in pairs(params) do
    self:addHeader(key, value)
  end

  return self
end

function Response:contentType(value)
  return self:addHeader('Content-Type', value)
end

function Response:statusCode(statusCode, statusText)
  assert(not self._headersSended, "can't set status code, it was already sent")
  self.status = statusCode
  self._headFirstLine = string.gsub(self._templateFirstLine, '{{ STATUS_CODE }}', tostring(statusCode))
  self._headFirstLine = string.gsub(self._headFirstLine, '{{ STATUS_TEXT }}', statusText or STATUS_TEXT[statusCode] or "Unknown Status " .. statusCode)

  return self
end

function Response:_getHeaders()
  local headers = {}

  for header_name, header_value in pairs(self._headers) do
    if type(header_value) == "table" and #header_value > 0 then
      for _, sub_value in ipairs(header_value) do
        headers[#headers + 1] = header_name .. ': ' .. sub_value .. '\r\n'
      end
    else
      headers[#headers + 1] = header_name .. ': ' .. header_value .. '\r\n'
    end
  end

  return table.concat(headers)
end

function Response:writeDefaultErrorMessage(statusCode, errMessage)
  self:statusCode(statusCode)
  local content = string.gsub(DEFAULT_ERROR_MESSAGE, '{{ STATUS_CODE }}', statusCode)
  self:write(string.gsub(content, '{{ STATUS_TEXT }}', errMessage or STATUS_TEXT[statusCode]), false)

  return self
end

function Response:close()
  local body = self._writeHandler:processBodyData(nil, true, self)

  if body and #body > 0 then
    self._client:send(toHex(#body) .. '\r\n' .. body .. '\r\n')
  end

  self._client:send('0\r\n\r\n')
  self.close = true  -- TODO: this seems unused??

  return self
end

function Response:sendOnlyHeaders()
  self:sendHeaders(false, '')
  self:write('\r\n')

  return self
end

function Response:sendHeaders(stayOpen, body)
  if self._headersSended then
    return self
  end

  if stayOpen then
    self:addHeader('Transfer-Encoding', 'chunked')
  elseif type(body) == 'string' then
    self:addHeader('Content-Length', body:len())
  end

  self:addHeader('Date', os.date('!%a, %d %b %Y %H:%M:%S GMT', os.time()))

  if not self._headers['Content-Type'] then
    self:addHeader('Content-Type', 'text/html')
  end

  self._headersSended = true
  self._client:send(self._headFirstLine .. self:_getHeaders() .. '\r\n')
  self._chunked = stayOpen

  return self
end

function Response:write(body, stayOpen)
  body = self._writeHandler:processBodyData(body or '', stayOpen, self)
  self:sendHeaders(stayOpen, body)

  self._isClosed = not stayOpen

  if self._isClosed then
    self._client:send(body)
  elseif #body > 0 then
    self._client:send(
      toHex(#body) .. '\r\n' .. body .. '\r\n'
    )
  end

  if self._isClosed then
    self._client:close() -- TODO: remove this, a non-chunked body can also be sent in multiple pieces
  end

  return self
end

local function readfile(filename)
  local file, err = io.open(filename, 'rb')
  if not file then
    return nil, err
  end

  local value, err = file:read('*a')
  file:close()
  return value, err
end

-- return nil+err if not ok
function Response:writeFile(filename, contentType)
  if type(filename) ~= "string" then
    -- deprecated backward compatibility; file is a file-descriptor
    self:contentType(contentType)
    self:statusCode(200)
    local value = filename:read('*a')
    filename:close()
    self:write(value)
    return self
  end

  local contents, err = readfile(filename)
  if not contents then
    return nil, err
  end

  self:statusCode(200)
  self:contentType(contentType or mimetypes.guess(filename))
  self:write(contents)
  return self
end

-- download by browser, return nil+err if not ok
function Response:sendFile(path)
  local filename = path:match("[^/]*$") -- only filename, no path
  self:addHeader('Content-Disposition', 'attachment; filename="' .. filename .. '"')

  local ok, err = self:writeFile(path, 'application/octet-stream')
  if not ok then
    self:addHeader('Content-Disposition', nil)
    return nil, err
  end

  return self
end

function Response:redirect(location, temporary)
  self:statusCode(temporary and 302 or 301)
  self:addHeader('Location', location)
  self:sendOnlyHeaders()
  return self
end

return Response
