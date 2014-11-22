local Request = {}

function Request:new(client)
    local newObj = {}       
    self.__index = self  
    newObj.client = client
    newObj.firstLine = nil

    return setmetatable(newObj, self)
end

function Request:path()
    local isFirstLine = self.firstLine == nil

    if (isFirstLine) then
       self.firstLine = self.client:receive()
       local body = '.' .. string.match(self.firstLine, '^GET%s(.*)%sHTTP%/[0-9]%.[0-9]')
       local filename, querystring = string.match(body, '^([^#?]+)(.*)')
       self._path = filename
    end

    return self._path 
end

function Request:method()
  return "GET"
end

return Request