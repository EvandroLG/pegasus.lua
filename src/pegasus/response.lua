--- Response object available in callback handlers.
--
-- HTTP response writer used by your application callback.
-- Instances are created internally by Pegasus and passed to
-- the callback provided to `pegasus:start` and plugin handlers.
--
-- Notes:
--
-- - When streaming (`stayOpen == true`), Transfer-Encoding: chunked is used.
-- - For HEAD requests, bodies are automatically skipped.
--
-- Fields on the object:
--
-- * `response.log`: the logger object, to enable logging from handlers and plugins
-- * `response.request`: the related `pegasus.request` object
-- * `response.status`: the HTTP status code (defaults to 200), use `response:statusCode` to set the status
--
-- Quick example:
--
--     server:start(function(req, res)
--       res:statusCode(200)
--          :contentType('application/json')
--          :write('{"ok":true}')
--     end)
-- @classmod pegasus.response

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

-- Internal: construct a new Response.
-- @tparam table client accepted client socket
-- @tparam table writeHandler internal handler (provides `log` and body processing)
-- @treturn Response response
function Response:new(client, writeHandler)
  local newObj = {}
  newObj.log = writeHandler.log
  newObj._headersSended = false
  newObj._templateFirstLine = 'HTTP/1.1 {{ STATUS_CODE }} {{ STATUS_TEXT }}\r\n'
  newObj._headFirstLine = ''
  newObj._headers = {}
  newObj._isClosed = false
  newObj._client = client
  newObj._writeHandler = writeHandler
  newObj.status = 200
  newObj._skipBody = false -- for HEAD requests

  return setmetatable(newObj, self)
end

--- Add a response header.
-- Errors if headers were already sent downstream.
-- @tparam string key
-- @tparam string|number|array value (multiple headers by the same name can be set by passing an array of values)
-- @return The `pegasus.response` object to allow chaining calls.
function Response:addHeader(key, value)
  assert(not self._headersSended, "can't add header, they were already sent")
  self._headers[key] = value
  return self
end

--- Add multiple headers.
-- @tparam table params table of key-value pairs to add as headers (see `addHeader` for value types)
-- @return The `pegasus.response` object to allow chaining calls.
function Response:addHeaders(params)
  for key, value in pairs(params) do
    self:addHeader(key, value)
  end

  return self
end

--- Set the `Content-Type` header.
-- @tparam string value
-- @return The `pegasus.response` object to allow chaining calls.
function Response:contentType(value)
  return self:addHeader('Content-Type', value)
end

--- Set the HTTP status line.
-- Must be called before headers are sent downstream.
-- @tparam number statusCode
-- @tparam[opt] string statusText (defaults to standard text for the code)
-- @return The `pegasus.response` object to allow chaining calls.
function Response:statusCode(statusCode, statusText)
  assert(not self._headersSended, "can't set status code, it was already sent")
  self.status = statusCode
  self._headFirstLine = string.gsub(self._templateFirstLine, '{{ STATUS_CODE }}', tostring(statusCode))
  self._headFirstLine = string.gsub(self._headFirstLine, '{{ STATUS_TEXT }}', statusText or STATUS_TEXT[statusCode] or "Unknown Status " .. statusCode)

  return self
end

--- Instruct response to skip writing the response body.
-- This is automatically called by the `pegasus.request` object for HEAD requests. There should be no need
-- to call this manually.
-- @tparam[opt=true] boolean skip
-- @return The `pegasus.response` object to allow chaining calls.
function Response:skipBody(skip)
  if skip == nil then
    skip = true
  end
  self._skipBody = not not skip
  return self
end

-- Internal: serialize headers.
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

--- Write a default HTML error body for a given status.
-- @tparam number statusCode
-- @tparam[opt] string errMessage
-- @return The `pegasus.response` object to allow chaining calls.
function Response:writeDefaultErrorMessage(statusCode, errMessage)
  self:statusCode(statusCode)
  local content = string.gsub(DEFAULT_ERROR_MESSAGE, '{{ STATUS_CODE }}', statusCode)
  self:write(string.gsub(content, '{{ STATUS_TEXT }}', errMessage or STATUS_TEXT[statusCode]), false)

  return self
end

--- Finish a chunked response and mark as closed.
-- Idempotent; safe to call multiple times.
-- @return The `pegasus.response` object to allow chaining calls.
function Response:close()
  if not self.closed then
    local body = self._writeHandler:processBodyData(nil, true, self)

    if not self._skipBody then
      if body and #body > 0 then
        self._client:send(toHex(#body) .. '\r\n' .. body .. '\r\n')
      end

      self._client:send('0\r\n\r\n')
    end

    self.closed = true
  end

  return self
end

--- Send only the headers, without a body.
-- Useful for redirects and HEAD responses.
-- @return The `pegasus.response` object to allow chaining calls.
function Response:sendOnlyHeaders()
  self:sendHeaders(false, '')
  self:write('\r\n')

  return self
end

--- Send headers if not already sent.
-- Adds `Transfer-Encoding: chunked` when `stayOpen == true`; otherwise sets `Content-Length` when body is a string.
-- Also sets a default `Date` and `Content-Type` header if not present.
-- @tparam[opt=false] boolean stayOpen whether to keep the connection open for chunked streaming
-- @tparam[opt] string body current body chunk (used to set Content-Length)
-- @return The `pegasus.response` object to allow chaining calls.
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

--- Write response body.
-- When `stayOpen == true`, the body is sent as a chunk and the connection remains open.
-- When `stayOpen ~= true`, headers are sent with `Content-Length` and the client-socket is closed afterwards.
-- @tparam[opt=""] string body
-- @tparam[opt] boolean stayOpen
-- @return The `pegasus.response` object to allow chaining calls.
function Response:write(body, stayOpen)
  body = self._writeHandler:processBodyData(body or '', stayOpen, self)
  self:sendHeaders(stayOpen, body)

  self._isClosed = not stayOpen

  if not self._skipBody then
    if self._isClosed then
      self._client:send(body)
    elseif #body > 0 then
      self._client:send(
        toHex(#body) .. '\r\n' .. body .. '\r\n'
      )
    end
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

--- Write a file to the response with a 200 status.
-- @tparam string filename path to file
-- @tparam[opt] string contentType override content type, if omitted it will be guessed based on the filename extension
-- @return[1] The `pegasus.response` object to allow chaining calls.
-- @return[2] nil + err on failure
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

--- Send a file as an attachment (download).
-- @tparam string path path to file
-- @return[1] The `pegasus.response` object to allow chaining calls.
-- @return[2] nil + err on failure
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

--- Redirect to a different URL.
-- @tparam string location destination URL
-- @tparam[opt] boolean temporary when true uses 302, otherwise 301
-- @return The `pegasus.response` object to allow chaining calls.
function Response:redirect(location, temporary)
  self:statusCode(temporary and 302 or 301)
  self:addHeader('Location', location)
  self:sendOnlyHeaders()
  return self
end

return Response
