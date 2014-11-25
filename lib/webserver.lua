local socket = require 'socket'
local Request = require 'lib/request'
local Response = require 'lib/response'


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
    print('GET')
    response:processes(request, response)
end

function HTTPServer:POST(request, response)
    print('POST')
    response:processes(request)
end


http = HTTPServer:new('9090')
http:start()
