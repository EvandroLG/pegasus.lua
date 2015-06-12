local mimetypes = require 'mimetypes'
local File = require 'pegasus.file'


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

function Response:new()
  local newObj = {}
  self.__index = self
  newObj.body = ''
  newObj.headFirstLine = 'HTTP/1.1 {{ STATUS_CODE }} {{ STATUS_TEXT }}\r\n'
  newObj.headers = {}
  newObj.status = 200
  newObj.content = ''
  newObj.filename = ''

  return setmetatable(newObj, self)
end

function Response:_process(request, location)
  self.filename = '.' .. location .. request:path()
  local content = File:open(self.filename)

  if not content then
    self:_prepareWrite(content, 404)
    return
  end

  try {
    function()
      self:_prepareWrite(content, 200)
    end
  } catch {
    function(error)
      self:_prepareWrite(content, 500)
    end
  }
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
  self.headFirstLine = string.gsub(self.headFirstLine, '{{ STATUS_CODE }}', statusCode)
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

function Response:_prepareWrite(body, statusCode)
  self:statusCode(statusCode or 200)
  local content = body

  if statusCode >= 400 then
    content = string.gsub(DEFAULT_ERROR_MESSAGE, '{{ STATUS_CODE }}', statusCode)
    content = string.gsub(content, '{{ STATUS_TEXT }}', STATUS_TEXT[statusCode])
  end

  self:write(content)
end

function Response:_setDefaultHeaders()
  if not self.headers['Content-Type'] then
    self:addHeader('Content-Type', mimetypes.guess(self.filename or '') or 'text/html')
  end

  if not self.headers['Content-Length'] then
    self:addHeader('Content-Length', File:size(self.filename) or 0)
  end
end

function Response:write(body)
  self:_setDefaultHeaders()
  local head = self:_getHeaders()
  self.content = self.headFirstLine .. head .. body

  return self
end

function Response:writeFile(file)
  local file = io.open(file, 'r')
  local value = file:read('*all')
  self:write(value)

  return self
end

return Response

