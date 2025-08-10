--- Module `pegasus.plugins.compress`
--
-- Response body compressor that applies gzip when the client accepts it
-- and compression is beneficial. Works with both `lua-zlib` and `lzlib`.
--
-- Behavior:
-- - Detects `Accept-Encoding: gzip` on the request (or `Content-Encoding` already set)
-- - Sets `Content-Encoding: gzip` when compressing
-- - Supports streaming with chunked encoding; maintains an internal zlib stream
-- - Leaves content unchanged when compression does not reduce size
--
-- Options for `Compress:new{ ... }`:
-- - `level`: zlib compression level (defaults to zlib default; use `NO_COMPRESSION` to disable)
--
-- @module pegasus.plugins.compress

local ZlibStream = {} do
  local zlib = require "zlib"

  local function zlib_name(lib)
    if lib._VERSION and string.find(lib._VERSION, 'lua-zlib', nil, true) then
      return 'lua-zlib'
    end

    if lib._VERSION and string.find(lib._VERSION, 'lzlib', nil, true) then
      return 'lzlib'
    end
  end

  local z_lib_name = assert(zlib_name(zlib), 'Unsupported zlib Lua binding')


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
  Compress.__index = Compress

  Compress.NO_COMPRESSION      = ZlibStream.NO_COMPRESSION
  Compress.BEST_SPEED          = ZlibStream.BEST_SPEED
  Compress.BEST_COMPRESSION    = ZlibStream.BEST_COMPRESSION
  Compress.DEFAULT_COMPRESSION = ZlibStream.DEFAULT_COMPRESSION

  --- Create a new `Compress` plugin instance.
  -- @tparam[opt] table options
  -- @tparam[opt] number options.level zlib compression level
  -- @treturn table plugin instance
  ---@param options table|nil
  ---@return Compress
  function Compress:new(options)
    local compress = {}
    compress.options = options or {}

    return setmetatable(compress, self)
  end

  --- Compress response body data when appropriate.
  --
  -- Invoked for every body chunk. When `stayOpen` is true, keeps an internal
  -- zlib stream and returns the compressed chunk. On the final call with
  -- `data == nil`, closes the stream and returns any trailer bytes.
  --
  -- If compression does not reduce size (for non-streaming case), the
  -- original `data` is returned and no `Content-Encoding` header is set.
  --
  -- @tparam string|nil data body chunk, or `nil` to finish streaming
  -- @tparam boolean stayOpen whether the response is streaming (chunked)
  -- @tparam table request request object
  -- @tparam table response response object
  -- @treturn string data possibly compressed
  ---@param data string|nil
  ---@param stayOpen boolean
  ---@param request table
  ---@param response table
  ---@return string
  function Compress:processBodyData(data, stayOpen, request, response)
    local accept_encoding

    if response.headersSended then
      accept_encoding = response.headers['Content-Encoding'] or ''
    else
      local headers = request:headers()
      accept_encoding = headers and headers['Accept-Encoding'] or ''
    end

    local accept_gzip = not not accept_encoding:find('gzip', nil, true)

    if accept_gzip and self.options.level ~= ZlibStream.NO_COMPRESSION then
      local stream = response.compress_stream
      local buffer = response.compress_buffer

      if not stream then
        local writer = function (zdata) buffer[#buffer + 1] = zdata end
        stream, buffer = ZlibStream:new(writer, self.options.level, nil, 31), {}
      end

      if stayOpen then
        if data == nil then
          stream:close()
          response.compress_stream = nil
          response.compress_buffer = nil
        else
          stream:write(data)
          response.compress_stream = stream
          response.compress_buffer = buffer
        end

        local compressed = table.concat(buffer)
        for i = 1, #buffer do buffer[i] = nil end
        if not response.headersSended then
          response:addHeader('Content-Encoding', 'gzip')
        end

        return compressed
      end

      stream:write(data)
      stream:close()
      local compressed = table.concat(buffer)

      if #compressed < #data then
        if not response.headersSended then
          response:addHeader('Content-Encoding', 'gzip')
        end

        return compressed
      end
    end

    return data
  end
end

return Compress
