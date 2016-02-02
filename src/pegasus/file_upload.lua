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
  local count = 1

  for line in string.gmatch(body, "[^\r\n]+") do
    if count == 1 then
        table.insert(output, {})
    elseif count == 2 or count == 3 then
      local key, value = string.match(line, '([%w-]+): (%w.*)')
      output[#output][key] = value
    else if count >= 6 then
        if string.find(body, '------') then
            count = 1
            table.insert(output, {})
        else
            if output[#output].content then
                output[#output].content = output[#output].content .. line
            else
                output[#output].content = line
            end
        end
    end

    count = count + 1
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

function FileUpload:_createFile(filename, content)
    local file = io.open(filename)
    file:write(content)
    file:close()
end

function FileUpload:_saveFiles(files)
  for k, obj in pairs(files) do
    local directory = self.destination[obj['Content-Type']]
    local key, filename = string.match(obj['Content-Disposition'], '(filename=)(.*)')
    filename = directory .. string.gsub(filename, '"', '')

    self:_createFile(filename, obj.content)
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
