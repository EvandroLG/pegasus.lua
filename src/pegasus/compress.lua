local gzip = require "gzip"
local zlib = require "zlib"
local Compress = {}

function bytes(x)
  local b4=x%256  x=(x-x%256)/256
  local b3=x%256  x=(x-x%256)/256
  local b2=x%256  x=(x-x%256)/256
  local b1=x%256  x=(x-x%256)/256
  return string.char(b1,b2,b3,b4)
end

function Compress:processData(data, stayOpen, request, response)
  local accept_encoding = request:headers()['Accept-Encoding'] or '';
  local accept_gzip = accept_encoding:find('gzip') ~= nil
  if not stayOpen and accept_gzip then
    response:addHeader('Content-Encoding',  'gzip')

    local dataTable = {}
    local dataWrite = function (zdata)
       table.insert(dataTable, zdata)
    end

    local stream = zlib.deflate(dataWrite,
     -1, nil, 15 + 16)
    stream:write(data)
    stream:close()
    return table.concat(dataTable);

  else
    return data
  end
end

return Compress
