local Request = {}

function Request:new(client)
    local newObj = {}       
    self.__index = self  
    newObj.client = client
    newObj.line = nil

    return setmetatable(newObj, self)
end

function Request:path()
    if (not self._path) then
       self.line = self.line or self.client:receive()
       local method, body = string.match(self.line, '^(.*)%s(.*)%sHTTP%/[0-9]%.[0-9]')
       local filename, querystring = string.match(body, '^([^#?]+)(.*)')
       self._path = '.' .. filename
    end

    return self._path
end

function Request:method()
    self.line = self.line or self.client:receive()
    local method, body = string.match(self.line, '^(.*)%s(.*)%sHTTP%/[0-9]%.[0-9]')

    return method
end

return Request