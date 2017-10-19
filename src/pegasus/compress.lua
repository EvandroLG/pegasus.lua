local zlib = require "zlib"

local Compress = {}
Compress.__index = Compress

function Compress:new(options)
  local compress = {}

  compress.options = options or {}

  return setmetatable(compress, self)
end

function Compress:processBodyData(data, stayOpen, request, response)
  local accept_encoding = request:headers()['Accept-Encoding'] or ''
  local accept_gzip = accept_encoding:find('gzip') ~= nil

  if not stayOpen and accept_gzip then
    response:addHeader('Content-Encoding',  'gzip')

    local dataTable = {}
    local dataWrite = function (zdata)
       table.insert(dataTable, zdata)
    end

    local stream = zlib.deflate(dataWrite,
                   self.options.level or -1 , nil, 15 + 16)

    stream:write(data)
    stream:close()

    return table.concat(dataTable)
  else
    return data
  end
end

return Compress
