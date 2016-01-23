local FileUpload = {}

function FileUpload:new()
    local obj = {}
    self.__index = self
    obj.content_type_filter = {}
    obj.content_type_discover = {}
    obj.destination = ''
    obj.min_body_size = nil
    obj.max_body_size = nil

    return setmetatable(obj, self)
end

function FileUpload:processBodyData(data, stay_open, request, response)
end

return FileUpload
