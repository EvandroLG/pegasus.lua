local socket = require 'socket'
local mimetypes = require 'mimetypes'
local Request = require 'lib/request'
local Response = require 'lib/response'


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
        <p>Error code: {{ CODE }}</p>
        <p>Message: {{ MESSAGE }}.</p>
    </body>
    </html>
]]

local DEFAULT_HEAD = 'HTTP/1.1 {{ STATUS_CODE }} OK\r\nContent-Type: {{ MIME_TYPE }};charset=utf-8\r\n\r\n'

local RESPONSES = {
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


-- solution by @cwarden - https://gist.github.com/cwarden/1207556
local function catch(what)
   return what[1]
end

local function try(what)
   status, result = pcall(what[1])

   if not status then
      what[2](result)
   end

   return result
end

local function fileOpen(filename)
    local file = io.open(filename, 'r')

    if file then
        return file:read('*all')
    end

    return nil
end

local HTTPServer = {}

function HTTPServer:new(port)
    self.port = port or '9090'
    return self
end

function HTTPServer:start()
    local server = assert(socket.bind("*", self.port))
    local ip, port = server:getsockname()
    print("Server is up on port " .. self.port)

    while 1 do
        local client = server:accept()

        client:settimeout(30)
        self:processRequest(client)
        client:close()
    end
end

function HTTPServer:processRequest(client)
    local request = Request:new(client)
    local response =  Response:new(client)
    local method = request:method()

    if method == 'GET' then
        self:GET(request, response)
    elseif method == 'POST' then
        self:POST(request, response)
    end

    client:send(response.body)
end

function HTTPServer:GET(request, response)
    print(request:path())
    local content = fileOpen(request:path())

    if content then
          try {
              function()
                  response.body = self:createContent(request:path(), content, 200)
              end,

              catch {
                  function(error)
                      response.body = self:createContent(request:path(), content, 500)
                  end
              }
          }

          return
      end

      response.body = self:createContent(request:path(), DEFAULT_ERROR_MESSAGE, 404)
end

function HTTPServer:POST(request, response)
    print('post')
end

function HTTPServer:createContent(filename, response, statusCode)
    local head = self:makeHead(filename, statusCode)

    if statusCode >= 400 then
        response = string.gsub(response, '{{ CODE }}', statusCode)
        response = string.gsub(response, '{{ MESSAGE }}', RESPONSES[statusCode])
    end

    return head .. response
end

function HTTPServer:makeHead(filename, statusCode)
    local mimetype = mimetypes.guess(filename) or 'text/html'
    local head = string.gsub(DEFAULT_HEAD, '{{ MIME_TYPE }}', mimetype)
    head = string.gsub(head, '{{ STATUS_CODE }}', statusCode)

    return head
end

function HTTPServer:sendResponse()
    
end

http = HTTPServer:new('9090')
http:start()