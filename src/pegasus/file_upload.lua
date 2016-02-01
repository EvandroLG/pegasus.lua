local function _startsWith(str, start)
  return string.sub(str, 1, #start) == start
end

local function _isIn(value, datas)
  for k, v in pairs(data) do
    if v == value then return true end
  end

  return false
end

local FileUpload = {}

function FileUpload:new()
    local obj = {}
    self.__index = self
    obj.contentTypeFilter = {}
    obj.contentTypeDiscover = {}
    obj.destination = {}
    obj.minBodySize = nil
    obj.maxBodySize = nil

    return setmetatable(obj, self)
end

function FileUpload:_getDatasFromFiles(body)
  local output = {}
  local data = {}

  for line in string.gmatch(body, "[^\r\n]+") do
    if _startsWith(line, '---') then
      table.insert(output, data)
    else
      local key, value = string.match(line, '([%w-]+): (%w.*)')
      output[#output][key] = value
    end
  end

  return output
end

function FileUpload:_isContentTypeValid(files)
  for k, obj in pairs(files) do
    if not _isIn(obj['Content-Type'], self.contentTypeFilter) then
      return false
    end
  end

  return true
end

function FileUpload:_createFile(filename)
    local file = io.open(filename)
    file:write()
    file:close()
end

function FileUpload:_saveFiles(files)
  for k, obj in pairs(files) do
    local directory = self.destination[obj['Content-Type']]
    local key, filename = string.match(obj['Content-Disposition'], '(filename=)(.*)')
    filename = string.gsub(filename, '"', '')

    self:_createFile(filename)
  end
end

function FileUpload:processBodyData(data, stayOpen, request, response)
  local headers = request:headers()
  local hasUpload = type(headers) == 'table' and
                    string.find(headers['Content-Type'], 'multipart/form-data')

  if not hasUpload then return end

  local body = request:receiveBody()
  if type(body) ~= 'string' then return end

  local files = self:_getDatasFromFiles(body)
  if not self:_isContentTypeValid(files) then return end

  self:_saveFiles(files)
end

return FileUpload
