-- solution by @cwarden - https://gist.github.com/cwarden/1207556
local function catch(what)
   return what[1]
end

local function try(what)
  local status, result = pcall(what[1])

  if not status then
    what[2](result)
  end

  return result
end

function dec2hex(dec)
local b,k,out,i,d=16,"0123456789ABCDEF","",0
  while dec > 0 do
    i=i+1
    local m = dec - math.floor(dec/b)*b
    dec, d = math.floor(dec/b), m + 1
    out = string.sub(k,d,d)..out
  end
  return out
end

local STATUS_TEXT = {
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
  [500] = 'Internal Server Error',
  [501] = 'Not Implemented',
  [502] = 'Bad Gateway',
  [503] = 'Service Unavailable',
  [504] = 'Gateway Time-out',
  [505] = 'HTTP Version not supported',
}

local DEFAULT_ERROR_MESSAGE = [[
  <!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN'
      'http://www.w3.org/TR/html4/strict.dtd'>
  <html>
  <head>
      <meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
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

function Response:new(client, writeHandler)
  local newObj = {}
  self.__index = self
  newObj.headers_sended = false
  newObj.templateFirstLine = 'HTTP/1.1 {{ STATUS_CODE }} {{ STATUS_TEXT }}\r\n'
  newObj.headFirstLine = ''
  newObj.headers = {}
  newObj.status = 200
  newObj.filename = ''
  self.closed = false
  self.client = client
  self.writeHandler = writeHandler

  return setmetatable(newObj, self)
end


function Response:addHeader(key, value)
  self.headers[key] = value
  return self
end

function Response:addHeaders(params)
  for key, value in pairs(params) do
    self.headers[key] = value
  end

  return self
end

function Response:contentType(value)
  self.headers['Content-Type'] = value
  return self
end

function Response:statusCode(statusCode, statusText)
  self.status = statusCode
  self.headFirstLine = string.gsub(self.templateFirstLine, '{{ STATUS_CODE }}', statusCode)
  self.headFirstLine = string.gsub(self.headFirstLine, '{{ STATUS_TEXT }}', statusText or STATUS_TEXT[statusCode])
  return self
end

function Response:_getHeaders()
  local headers = ''

  for key, value in pairs(self.headers) do
    headers = headers .. key .. ': ' .. value .. '\r\n'
  end

  return headers
end

function Response:writeDefaultErrorMessage(statusCode)
  self:statusCode(statusCode)
  local content = string.gsub(DEFAULT_ERROR_MESSAGE, '{{ STATUS_CODE }}', statusCode)
  self:write(string.gsub(content, '{{ STATUS_TEXT }}', STATUS_TEXT[statusCode]), false)
  return self
end

function Response:close()
  self.client:send('0\r\n\r\n')
  self.close = true
end

function Response:sendOnlyHeaders()
  self:sendHeaders(false, '')
  self:write('\r\n')
end

function Response:sendHeaders(stayOpen, body)
  if self.headers_sended then
    return self
  end

  if stayOpen then
    self:addHeader('Transfer-Encoding', 'chunked')
  elseif type(body) == 'string' then
    self:addHeader('Content-Length', body:len())
  end

  self:addHeader('Date', os.date('!%a, %d %b %Y %T GMT', os.time()))

  if not self.headers['Content-Type'] then
    self:addHeader('Content-Type', 'text/html')
  end

  self.client:send(self.headFirstLine .. self:_getHeaders())
  self.client:send('\r\n')
  self.headers_sended = true

  return self
end

function Response:write(body, stayOpen)
  body = self.writeHandler:processBodyData(body, stayOpen, self)
  self:sendHeaders(stayOpen, body)

  self.closed = not (stayOpen or false)
  if self.closed then
    self.client:send(body)
  else
    self.client:send(dec2hex(body:len())..'\r\n'..body..'\r\n')
  end

  if self.closed then
    self.client:close()
  end

  return self
end

function Response:writeFile(file, contentType)
  self:contentType(contentType)
  self:statusCode(200)
  local value = file:read('*a')
  self:write(value)

  return self
end

return Response

