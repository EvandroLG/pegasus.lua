local Request = {}

function Request:new(client)
    local newObj = {}       
    self.__index = self  
    newObj.client = client
    newObj.firstLine = nil
    newObj._method = nil
    newObj._path = nil
    newObj._params = {}
    newObj._headers_parsed = false
    newObj._headers = {}
    newObj._form = {}
    newObj._is_valid = false
    newObj._body = ''
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
function Request:parse_url_encoded(value, _table)
    --value exists and _table is empty
       if value and next(_table) == nil then
         for k, v in  string.gmatch(value, Request.PATTERN_QUERY_STRING) do
           _table[k] = v
         end 
       end
       return _table   
end
function Request:params()
    self:parseFirstLine()
    return self:parse_url_encoded(self._query_string, self._params)
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
    if self._headers_parsed then 
        return self._headers
    end
        
    self:parseFirstLine()
    local data = self.client:receive()
    while (not (data == nil)) and (data:len() > 0)  do
        local k , v =string.match(data, Request.PATTERN_HEADER)
        if k and v then
           self._headers[k] = v
        end
        data = self.client:receive()
    end
    self._headers_parsed = true
    return self._headers
end

function Request:body()
  self:headers()
  local data, err = self.client:receive()
  while (err == nil) and (not (data == nil)) do
      self._body = self._body .. data
      data = self.client:receive()
  end
  return self._body
end

function Request:form()
  return self:parse_url_encoded(self:body(), self._form)
end

function Request:file()
    
end

return Request
