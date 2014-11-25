local Request = {}

function Request:new(client)
    local newObj = {}       
    self.__index = self  
    newObj.client = client
    newObj.firstLine = nil
    newObj._method = nil
    newObj._path = nil
    newObj._params = {}
    newObj._headers = {}
    newObj._is_valid = false
    return setmetatable(newObj, self)
end

Request.PATTERN_METHOD = '^(.*)%s'
Request.PATTERN_PATH = '(.*)%s'
Request.PATTERN_PROTOCOL = '(HTTP%/[0-9]%.[0-9])'
Request.PATTERN_REQUEST = (Request.PATTERN_METHOD .. 
  Request.PATTERN_PATH ..Request.PATTERN_PROTOCOL) 

function Request:parseFirstLine()
    if (self.firstLine == nil) then
        self.firstLine = self.client:receive()
        -- Parse firstline http: METHOD PATH PROTOCOL, 
        -- GET Makefile HTTP/1.1 
        local method, path, protocol= string.match(self.firstLine, 
            Request.PATTERN_REQUEST)
            
        local filename, querystring = string.match(path, '^([^#?]+)(.*)')
        self._path = '.' .. path 
        self._query_string = querystring
        self._method = method
    end
end

Request.PATTERN_QUERY_STRING = '(%w)=(%w)'
function Request:params()
    self:parseFirstLine()
    --QueryString exists and params is empty
    if self._query_string and next(self._params) == nil then
      for k, v in  string.gmatch(self._query_string, Request.PATTERN_QUERY_STRING) do
        self._params[k] = v
      end 
    end
    return self._params
end

function Request:path()
  self:parseFirstLine()
  return self._path 
end

function Request:method()
    self:parseFirstLine()
    return self._method
end

Request.PATTERN_HEADER = "(%w):(%w)"

function Request:headers()
    self:parseFirstLine()
    local data = self.client:receive()
    while data  do
        local k , v =string.match(data, Request.PATTERN_HEADER)
        if k and v then
           self._headers[k] = v
        end
        data = self.client:receive()
    end

    return self._headers
end

return Request
