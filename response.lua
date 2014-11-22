local Response = {}
function Response:new(client)
    local newObj = {}       
    self.__index = self  
    newObj.body = ""
    return setmetatable(newObj, self)
end

return Response