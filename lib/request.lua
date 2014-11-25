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

    return setmetatable(newObj, self)
end

function Request:parseFirstLine()
    if (self.firstLine == nil) then
        self.firstLine = self.client:receive()
        local method, body = string.match(self.firstLine, '^(.*)%s(.*)%sHTTP%/[0-9]%.[0-9]')
        local filename, querystring = string.match(body, '^([^#?]+)(.*)')
        self._path = '.' .. filename
        self._query_string = querystring
        self._method = method
    end
end

function Request:params()
    for param in string.gmatch(self._query_string, "%w=%w") do
      local equal = param:find("=")
      self._params[param:sub(1, equal-1)] = param:sub(equal+1)
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

function Request:headers()
    local data = self.client:receive()

    while data:len() > 0  do
        local doubleDot = r:find(':')
        local key = r:sub(1, doubleDot - 1)
        local value = r:sub(doubleDot + 1)

        self._headers[key] = value
        data = self.client:receive()
    end

    return self._headers
end

return Request