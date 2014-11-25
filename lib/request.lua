local Request = {}
function Request:new(client)
    local newObj = {}       
    self.__index = self  
    newObj.client = client
    newObj.firstLine = nil
    newObj._method = "GET"
    newObj._query_string = "GET"
    newObj._params = {}
    newObj._headers = {}

    return setmetatable(newObj, self)
end

function Request:parseFirstLine()
    if (self.firstLine == nil) then
       self.firstLine = self.client:receive()      
       local body = '.' .. string.match(self.firstLine, '^GET%s(.*)%sHTTP%/[0-9]%.[0-9]')
       local filename, querystring = string.match(body, '^([^#?]+)(.*)')
       self._path = filename
       self._query_string = querystring

       if not self.firstLine:find(self._method)  == 1 then
          local firstSpace = self.firstLine:find(" ")
          self._method = self.firstLine:sub(1, fisrtSpace)    
       end
    end 
end

function Request:params()
    for kv in string.gmatch(self._query_string, "%w=%w") do
      local equal = kv:find("=")
      self._params[kv:sub(1, equal-1)] = kv:sub(equal+1)
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
  local r, e = self.client:receive()

  while e == nil do
     local doubleDot = r:find(":")
     self._headers[r:sub(1, doubleDot-1)] = r:sub(doubleDot+1)
     r, e = self.client:receive()
  end

  return self._headers
end

return Request