socket = require 'socket'

DEFAULT_ERROR_MESSAGE = [[
    <!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN'
        'http://www.w3.org/TR/html4/strict.dtd'>
    <html>
    <head>
        <meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
        <title>Error response</title>
    </head>
    <body>
        <h1>Error response</h1>
        <p>Error code: %(code)d</p>
        <p>Message: %(message)s.</p>
        <p>Error code explanation: %(code)s - %(explain)s.</p>
    </body>
    </html>
]]

DEFAULT_ERROR_CONTENT_TYPE = 'text/html;charset=utf-8'

RESPONSES = {
    s100 = 'Continue',
    s101 = 'Switching Protocols',
    s200 = 'OK',
    s201 = 'Created',
    s202 = 'Accepted',
    s203 = 'Non-Authoritative Information',
    s204 = 'No Content',
    s205 = 'Reset Content',
    s206 = 'Partial Content',
    s300 = 'Multiple Choices',
    s301 = 'Moved Permanently',
    s302 = 'Found',
    s303 = 'See Other',
    s304 = 'Not Modified',
    s305 = 'Use Proxy',
    s307 = 'Temporary Redirect',
    s400 = 'Bad Request',
    s401 = 'Unauthorized',
    s402 = 'Payment Required',
    s403 = 'Forbidden',
    s404 = 'Not Found',
    s405 = 'Method Not Allowed',
    s406 = 'Not Acceptable',
    s407 = 'Proxy Authentication Required',
    s408 = 'Request Time-out',
    s409 = 'Conflict',
    s410 = 'Gone',
    s411 = 'Length Required',
    s412 = 'Precondition Failed',
    s413 = 'Request Entity Too Large',
    s414 = 'Request-URI Too Large',
    s415 = 'Unsupported Media Type',
    s416 = 'Requested range not satisfiable',
    s417 = 'Expectation Failed',
    s500 = 'Internal Server Error',
    s501 = 'Not Implemented',
    s502 = 'Bad Gateway',
    s503 = 'Service Unavailable',
    s504 = 'Gateway Time-out',
    s505 = 'HTTP Version not supported',
}

HTTPServer = {}

fileOpen = function(filename)
    local file = io.open(filename, 'r')
    return file:read('*all')
end

function HTTPServer:new(port)
    local self = {}
    self.port = port or '9090'
    setmetatable(self, { __index = HTTPServer })

    return self
end

function HTTPServer:bind()
    local server = assert(socket.bind("*", self.port))
    local ip, port = server:getsockname()
    print("Please telnet to localhost on port " .. self.port)

    while 1 do
        local client = server:accept()
        client:settimeout(10)

        local line, err = client:receive()
        local isValid = not err

        if isValid then
            self:doGET(client, line)
        end

        client:close()
    end
end

function HTTPServer:doGET(client, line)
    local filename = '.' .. string.match(line, '^GET%s(.*)%sHTTP%/[0-9]%.[0-9]')
    local content = fileOpen(filename)

    client:send(content)
end

function HTTPServer:sendHead()
end

http = HTTPServer:new('9090')
http:bind()
-- local server = assert(socket.bind("*", 0))
-- -- find out which port the OS chose for us
-- local ip, port = server:getsockname()
-- -- print a message informing what's up
-- print("Please telnet to localhost on port " .. port)
-- print("After connecting, you have 10s to enter a line to be echoed")
-- -- loop forever waiting for clients
-- while 1 do
--   -- wait for a connection from any client
--   local client = server:accept()
--   -- make sure we don't block waiting for this client's line
--   client:settimeout(10)
--   -- receive the line
--   local line, err = client:receive()
--   -- if there was no error, send it back to the client
--   if not err then client:send(line .. "\n") end
--   -- done with client, close the object
--   client:close()
-- end