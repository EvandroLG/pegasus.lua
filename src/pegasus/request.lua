local lhp = require "http.parser"

local pp = function()end

local function parser_create(self)
  local parser

  parser = lhp.request{
    on_url = function(u)
      self._complete.url = true

      self._method = parser:method()
      self._ver_maj, self._ver_min = parser:version()

      local url = lhp.parse_url(u, true)
      pp('parser::on_url', u, url)

      if url then
        self._path         = url.path
        self._query_string = url.query
        self._fragment     = url.fragment
      end
    end;

    on_header = function(k, v)
      pp('parser::on_header', k, v)
      self._headers[k] = v
    end;

    on_headers_complete = function()
      pp('parser::on_headers_complete')
      self._complete.hdr = true
    end;

    on_message_complete = function()
      pp('parser::on_message_complete')
      self._complete.msg = true
      self._error = 'closed'
    end;

    on_body = function(chunk)
      pp('parser::on_body', chunk)
      if chunk then
        self._body         = (self._body or '') .. chunk
        self._content_done = self._content_done + #chunk
      end
    end;

    on_chunk_header = function(content_length)
      pp('parser::on_chunk_header', content_length)
      self._content_done = 0
      self._content_length = content_length + 2 -- each chunk also has EOL
    end;

    on_chunk_complete = function(content_length)
      pp('parser::on_chunk_complete', chunk)
      self._content_length = nil
    end;
  }

  return parser
end

local function parser_error(parser)
  local no, name, msg = parser:error()
  if no and name and msg then
    return string.format('[HTTP-PARSER][%s] %s (%d)', name, msg, no)
  end

  return msg or name or no
end

-- just to be able easy to trace
local function parser_execute(self, chunk)
  pp('parser::execute::write', #chunk, chunk)
  local n = self._parser:execute(chunk)
  pp('parser::execute::result', n, parser_error(self._parser))
  return n
end

local function complete_by_eof(self, status)
  if (0 == parser_execute(self, '')) and (0 ~= self._parser:error()) then
    self._error = parser_error(self._parser)
  else
    self._error = status or 'closed'
  end

  self._complete.msg = true
  return nil, self._error
end

local Request = {}
Request.__index = Request

function Request:new(port, client)
  local newObj = {}

  newObj.client = client
  newObj.port = port
  newObj.ip = client:getpeername()

  newObj = setmetatable(newObj, self)

  return newObj:reset()
end

function Request:reset()
  if self._parser then self._parser:reset()
  else self._parser = parser_create(self) end

  self._method = nil
  self._path = nil
  self._ver_maj = nil
  self._ver_min = nil
  self._error = nil
  self._params = {}
  self._headers = {}
  self._body = nil -- buffer for parser::on_body callback
  self._data = nil -- buffer for receiveFullBody method
  self._content_done = 0 -- counter how many data readed

  self._complete = {
    url = false;
    msg = false;
    hdr = false;
  }

  return self
end

-- returns line with EOL characters
function Request:_receiveLine()
  if self._complete.msg then
    return nil, self._error or 'closed'
  end

  -- seems LuaSocket remove support for `*L` pattern
  -- so we add EOL by hand to all lines
  local line, status, part = self.client:receive()

  if line then line = line .. "\r\n"
  elseif part and #part > 0 then
    line = part
  end

  return line, status
end

function Request:_receiveChunk(size)
  if self._complete.msg then
    return nil, self._error or 'closed'
  end

  local line, status, part = self.client:receive(size)
  if not line then
    if part and #part == 0 then
      part = nil
    end
    line = part
  end
  return line, status
end

function Request:_receiveAndExecute(size)
  local line, status
  if size then
    line, status = self:_receiveChunk(size)
  else
    line, status = self:_receiveLine()
  end

  if line == nil then
    if status == 'timeout' then
      return nil, status
    end
    return complete_by_eof(self, status)
  end

  local n = parser_execute(self, line)
  if n ~= #line then
    self._error = parser_error(self._parser)
    self._complete.msg = true
    return nil, self._error
  end

  if status == 'closed' then
    return complete_by_eof(self, status)
  end

  if status == 'timeout' then
    return nil, status
  end

  return true
end

function Request:_waiting(typ)
  return (self._complete.msg ~= true) and (self._complete[typ] ~= true)
end

function Request:_receiveUntil(typ)
  while self:_waiting(typ) do
    local ok, err = self:_receiveAndExecute()
    if not ok then
      if self._complete[typ] then
        return true
      end
      return nil, err
    end
  end

  if self._complete[typ] then
    return true
  end

  return nil, self._error
end

function Request:parseFirstLine()
  return self:_receiveUntil('url')
end

Request.PATTERN_QUERY_STRING = '([^=]*)=([^&]*)&?'

function Request:parseURLEncoded(value, _table) -- luacheck: ignore self
  --value exists and _table is empty
  if value and next(_table) == nil then
    for k, v in  string.gmatch(value, Request.PATTERN_QUERY_STRING) do
        _table[k] = v
    end
  end

  return _table
end

function Request:params()
  local ok, err = self:parseFirstLine()
  if not ok then return nil, err end
  return self:parseURLEncoded(self._query_string, self._params)
end

function Request:post()
  if self:method() ~= 'POST' then return nil end

  local data, status = self:receiveFullBody()
  if not data then return nil, status end

  return self:parseURLEncoded(data, {})
end

function Request:path()
  local ok, err = self:parseFirstLine()
  if not ok then return nil, err end
  return self._path
end

function Request:method()
  local ok, err = self:parseFirstLine()
  if not ok then return nil, err end
  return self._method
end

function Request:version()
  local ok, err = self:parseFirstLine()
  if not ok then return nil, err end
  return self._ver_maj, self._ver_min
end

Request.PATTERN_HEADER = '([%w-]+): ([%w %p]+=?)'

function Request:headers()
  if self:_waiting('hdr') then
    local ok, err = self:_receiveUntil('hdr')
    if not ok then return nil, err end
    self._content_length = tonumber(self._headers["Content-Length"])
  end

  if self._complete.hdr then
    return self._headers
  end

  return nil, self._error
end

function Request:receiveBody(size)
  if self._body then
    local data = self._body
    self._body = nil
    return data
  end

  if self._complete.msg then
    return nil, self._error
  end

  -- receive next chunk for chunked encoded data
  if not self._content_length then
    if self._headers['Transfer-Encoding'] ~= 'chunked' then
      return false
    end

    local ok, err = self:_receiveAndExecute()
    if not ok then return nil, err end

    -- invalid sequence in chunked?
    if not self._content_length then
      if self._body then
        local data = self._body
        self._body = nil
        return data
      end
      return nil, 'no chunk size in chunked encoded content'
    end
  end

  assert(self._content_length)

  -- with chunked encoded receive no more than chunk size

  local rest = self._content_length - self._content_done

  if rest < 0 then
    return nil, 'protocol error'
  end

  size = size and size < rest and size or rest

  local ok, err = self:_receiveAndExecute(size)

  -- at first return all data we got. even if we get error in some case
  if self._body then
    local data = self._body
    self._body = nil
    return data
  end

  if self._complete.msg then
    return nil, self._error
  end

  -- We get here when receive timeout or
  -- if we receive some data but it is not enouth
  -- to build body.
  -- E.g. with chunked encoded data <DATA><EOL> we 
  -- receive just last EOL.
  -- Treats it as timeout is not fully correct because
  -- we ask receive only 2 bytes and got it. 
  -- But prev calls returns with timout.
  -- So to simplicity we treat it as timeout.

  return nil, err or 'timeout'
end

function Request:receiveFullBody()
  local body = self._data
  self._data = nil

  -- it can be chunked so we have to read all chunks
  while not self._complete.msg do
    local chunk, status = self:receiveBody()

    if not chunk then
      if status == 'closed' then
        return body
      end

      self._data = body
      return nil, status
    end

    body = (body or '') .. chunk

    if status == 'timeout' then
      self._data = body
      return nil, status
    end
  end

  return body
end

-- Does the request support keep alive connection.
function Request:support_keep_alive()
  -- we can reuse same connection if
  -- 1 - we read entire message
  -- 2 - client ask keep-alive (HTTP/1.1 default)
  return self._complete.msg and (self._error == 'closed') and self._parser:should_keep_alive()
end

return Request
