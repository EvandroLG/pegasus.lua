local zlib = require "zlib"

local function zlib_name(zlib)
  if zlib._VERSION and string.find(zlib._VERSION, 'lua-zlib', nil, true) then
    return 'lua-zlib'
  end

  if zlib._VERSION and string.find(zlib._VERSION, 'lzlib', nil, true) then
    return 'lzlib'
  end
end

local z_lib_name = assert(zlib_name(zlib), 'Unsupported zlib Lua binding')

local ZlibStream = {} do
ZlibStream.__index = ZlibStream

ZlibStream.NO_COMPRESSION      = zlib.NO_COMPRESSION       or  0
ZlibStream.BEST_SPEED          = zlib.BEST_SPEED           or  1
ZlibStream.BEST_COMPRESSION    = zlib.BEST_COMPRESSION     or  9
ZlibStream.DEFAULT_COMPRESSION = zlib.DEFAULT_COMPRESSION  or -1
ZlibStream.STORE               = 0
ZlibStream.DEFLATE             = 8

if z_lib_name == 'lzlib' then

function ZlibStream:new(writer, level, method, windowBits)
  level  = level or ZlibStream.DEFAULT_COMPRESSION
  method = method or ZlibStream.DEFLATE

  local o = setmetatable({
    zd = assert(zlib.deflate(writer, level, method, windowBits));
  }, self)

  return o
end

function ZlibStream:write(chunk)
  assert(self.zd:write(chunk))
end

function ZlibStream:close()
  self.zd:close()
end

elseif z_lib_name == 'lua-zlib' then

function ZlibStream:new(writer, level, method, windowBits)
  level  = level or ZlibStream.DEFAULT_COMPRESSION
  method = method or ZlibStream.DEFLATE

  assert(method == ZlibStream.DEFLATE, 'lua-zlib support only deflated method')

  local o = setmetatable({
    zd = assert(zlib.deflate(level, windowBits));
    writer = writer;
  }, self)

  return o
end

function ZlibStream:write(chunk)
  chunk = assert(self.zd(chunk))
  self.writer(chunk)
end

function ZlibStream:close()
  local chunk = self.zd('', 'finish')
  if chunk and #chunk > 0 then self.writer(chunk) end
end

end

end

local Compress = {} do

Compress.NO_COMPRESSION      = ZlibStream.NO_COMPRESSION
Compress.BEST_SPEED          = ZlibStream.BEST_SPEED
Compress.BEST_COMPRESSION    = ZlibStream.BEST_COMPRESSION
Compress.DEFAULT_COMPRESSION = ZlibStream.DEFAULT_COMPRESSION

function Compress:new(options)
  local compress= {}
  self.__index = self
  compress.options = options or {}

  return setmetatable(compress, self)
end

function Compress:processBodyData(data, stayOpen, request, response)
  local headers = request:headers()
  local accept_encoding = headers and headers['Accept-Encoding'] or ''
  local accept_gzip = not not accept_encoding:find('gzip', nil, true)

  if not stayOpen and accept_gzip and self.options.level ~= ZlibStream.NO_COMPRESSION then
    local dataTable = {}
    local dataWrite = function (zdata)
       table.insert(dataTable, zdata)
    end

    local stream = ZlibStream:new(dataWrite, self.options.level, nil, 31)
    stream:write(data)
    stream:close()

    local compressed = table.concat(dataTable)

    if #compressed < #data then
      response:addHeader('Content-Encoding', 'gzip')
      return compressed
    end
  end

  return data
end

end

return Compress
