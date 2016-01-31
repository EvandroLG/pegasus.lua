local function startsWith(str, start)
  return string.sub(str, 1, #start) == start
end

local FileUpload = {}

function FileUpload:new()
    local obj = {}
    self.__index = self
    obj.contentTypeFilter = {}
    obj.contentTypeDiscover = {}
    obj.destination = ''
    obj.minBodySize = nil
    obj.maxBodySize = nil

    return setmetatable(obj, self)
end

function FileUpload:getDatasFromFiles(body)
  local output = {}
  local data = {}

  for line in string.gmatch(body, "[^\r\n]+") do
    if startsWith(line, '---') then
      table.insert(output, data)
      data = {}
    else
      local key, value = string.match(line, '([%w-]+): (%w.*)')
      data[key] = value
    end
  end

  return output
end

function FileUpload:processBodyData(data, stayOpen, request, response)
  local headers = request:headers()
  local hasUpload = type(headers) == 'table' and
                    string.find(headers['Content-Type'], 'multipart/form-data')

  if not hasUpload then return end

  local body = request:receiveBody()

  if type(body) ~= 'string' or not self:isContentTypeValid(body) then
    return
  end

  local files = self:getDatasFromFiles(body)
end

return FileUpload
