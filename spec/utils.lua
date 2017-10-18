-------------------------------------------------------------------
-- lluv.utils.class
local function class(base)
  local t = base and setmetatable({}, base) or {}
  t.__index = t
  t.__class = t
  t.__base  = base

  function t.new(...)
    local o = setmetatable({}, t)
    if o.__init then
      if t == ... then -- we call as Class:new()
        return o:__init(select(2, ...))
      else             -- we call as Class.new()
        return o:__init(...)
      end
    end
    return o
  end

  return t
end

-------------------------------------------------------------------
-- lluv.utils.List
local List = class() do

function List:reset()
  self._first = 0
  self._last  = -1
  self._t     = {}
  return self
end

List.__init = List.reset

function List:push_front(v)
  assert(v ~= nil)
  local first = self._first - 1
  self._first, self._t[first] = first, v
  return self
end

function List:push_back(v)
  assert(v ~= nil)
  local last = self._last + 1
  self._last, self._t[last] = last, v
  return self
end

function List:peek_front()
  return self._t[self._first]
end

function List:peek_back()
  return self._t[self._last]
end

function List:pop_front()
  local first = self._first
  if first > self._last then return end

  local value = self._t[first]
  self._first, self._t[first] = first + 1

  return value
end

function List:pop_back()
  local last = self._last
  if self._first > last then return end

  local value = self._t[last]
  self._last, self._t[last] = last - 1

  return value
end

function List:size()
  return self._last - self._first + 1
end

function List:empty()
  return self._first > self._last
end

function List:find(fn, pos)
  pos = pos or 1
  if type(fn) == "function" then
    for i = self._first + pos - 1, self._last do
      local n = i - self._first + 1
      if fn(self._t[i]) then
        return n, self._t[i]
      end
    end
  else
    for i = self._first + pos - 1, self._last do
      local n = i - self._first + 1
      if fn == self._t[i] then
        return n, self._t[i]
      end
    end
  end
end

function List:remove(pos)
  local s = self:size()

  if pos < 0 then pos = s + pos + 1 end

  if pos <= 0 or pos > s then return end

  local offset = self._first + pos - 1

  local v = self._t[offset]

  if pos < s / 2 then
    for i = offset, self._first, -1 do
      self._t[i] = self._t[i-1]
    end
    self._first = self._first + 1
  else
    for i = offset, self._last do
      self._t[i] = self._t[i+1]
    end
    self._last = self._last - 1
  end

  return v
end

function List:insert(pos, v)
  assert(v ~= nil)

  local s = self:size()

  if pos < 0 then pos = s + pos + 1 end

  if pos <= 0 or pos > (s + 1) then return end

  local offset = self._first + pos - 1

  if pos < s / 2 then
    for i = self._first, offset do
      self._t[i-1] = self._t[i]
    end
    self._t[offset - 1] = v
    self._first = self._first - 1
  else
    for i = self._last, offset, - 1 do
      self._t[i + 1] = self._t[i]
    end
    self._t[offset] = v
    self._last = self._last + 1
  end

  return self
end

end
-------------------------------------------------------------------

-------------------------------------------------------------------
-- lluv.utils.Buffer
local Buffer = class() do

-- eol should ends with specific char.
-- `\r*\n` is valid, but `\r\n?` is not.

-- leave separator as part of first string
local function split_first_eol(str, sep, plain)
  local e, e2 = string.find(str, sep, nil, plain)
  if e then
    return string.sub(str, 1, e2), string.sub(str, e2 + 1), 0
  end
  return str
end

-- returns separator length as third return value
local function split_first_ex(str, sep, plain)
  local e, e2 = string.find(str, sep, nil, plain)
  if e then
    return string.sub(str, 1, e - 1), string.sub(str, e2 + 1), e2 - e + 1
  end
  return str
end

function Buffer:__init(eol, eol_is_rex)
  self._eol       = eol or "\n"
  self._eol_plain = not eol_is_rex
  self._lst       = List.new()
  self._size      = 0
  return self
end

function Buffer:reset()
  self._lst:reset()
  self._size = 0
  return self
end

function Buffer:eol()
  return self._eol, self._eol_plain
end

function Buffer:set_eol(eol, eol_is_rex)
  self._eol       = assert(eol)
  self._eol_plain = not eol_is_rex
  return self
end

function Buffer:append(data)
  if #data > 0 then
    self._lst:push_back(data)
    self._size = self._size + #data
  end
  return self
end

function Buffer:prepend(data)
  if #data > 0 then
    self._lst:push_front(data)
    self._size = self._size + #data
  end
  return self
end

local function read_line(self, split_line, eol, eol_is_rex)
  local plain

  if eol then plain = not eol_is_rex
  else eol, plain = self._eol, self._eol_plain end

  local lst = self._lst

  local ch = eol:sub(-1)
  local check = function(s) return not not string.find(s, ch, nil, true) end

  local t = {}
  while true do
    local i = self._lst:find(check)

    if not i then
      if #t > 0 then lst:push_front(table.concat(t)) end
      return
    end

    assert(i > 0)

    for i = i, 1, -1 do t[#t + 1] = lst:pop_front() end

    local line, tail, eol_len

    -- try find EOL in last chunk
    if plain or (eol == ch) then line, tail, eol_len = split_line(t[#t], eol, true) end

    if eol == ch then assert(tail) end

    if tail then -- we found EOL
      -- we can split just last chunk and concat
      t[#t] = line

      if #tail > 0 then lst:push_front(tail) end

      line = table.concat(t)
      self._size = self._size - (#line + eol_len)

      return line
    end

    -- we need concat whole string and then split
    -- for eol like `\r\n` this may not work well but for most cases it should work well
    -- e.g. for LuaSockets pattern `\r*\n` it work with one iteration but still we need
    -- concat->split because of case such {"aaa\r", "\n"}

    line, tail, eol_len = split_line(table.concat(t), eol, plain)

    if tail then -- we found EOL
      if #tail > 0 then lst:push_front(tail) end
      self._size = self._size - (#line + eol_len)
      return line
    end

    t[1] = line
    for i = 2, #t do t[i] = nil end
  end
end

function Buffer:read_line(eol, eol_is_rex)
  return read_line(self, split_first_ex, eol, eol_is_rex)
end

function Buffer:read_line_eol(eol, eol_is_rex)
  return read_line(self, split_first_eol, eol, eol_is_rex)
end

function Buffer:read_all()
  local t = {}
  local lst = self._lst
  while not lst:empty() do
    t[#t + 1] = self._lst:pop_front()
  end
  self._size = 0
  return table.concat(t)
end

function Buffer:read_some()
  if self._lst:empty() then return end
  local chunk = self._lst:pop_front()
  if chunk then self._size = self._size - #chunk end
  return chunk
end

function Buffer:read_n(n)
  n = math.floor(n)

  if n == 0 then
    if self._lst:empty() then return end
    return ""
  end

  local lst = self._lst
  local size, t = 0, {}

  while true do
    local chunk = lst:pop_front()

    if not chunk then -- buffer too small
      if #t > 0 then lst:push_front(table.concat(t)) end
      return
    end

    if (size + #chunk) >= n then
      assert(n > size)
      local pos = n - size
      local data = string.sub(chunk, 1, pos)
      if pos < #chunk then
        lst:push_front(string.sub(chunk, pos + 1))
      end

      t[#t + 1] = data

      self._size = self._size - n

      return table.concat(t)
    end

    t[#t + 1] = chunk
    size = size + #chunk
  end
end

function Buffer:read(pat, ...)
  if not pat then return self:read_some() end

  if pat == "*l" then return self:read_line(...) end

  if pat == "*L" then return self:read_line_eol(...) end

  if pat == "*a" then return self:read_all() end

  return self:read_n(pat)
end

function Buffer:empty()
  return self._lst:empty()
end

function Buffer:size()
  return self._size
end

function Buffer:next_line(data, eol)
  eol = eol or self._eol or "\n"
  if data then self:append(data) end
  return self:read_line(eol, true)
end

function Buffer:next_n(data, n)
  if data then self:append(data) end
  return self:read_n(n)
end

end
-------------------------------------------------------------------

-------------------------------------------------------------------
-- MOC for LuaSocket class
local Socket = {} do
Socket.__index = Socket

function Socket:new(fn)
  local o = setmetatable({}, self)

  o._writer = fn

  return o
end

local function return_resume(status, ...)
  if status then return ... end
  return nil, ...
end

local function start_reader(fn, self, pattern)
  local sender, err = coroutine.create(function ()
    local writer = function (...)
      return coroutine.yield(...)
    end
    fn(writer, self, pattern)
  end)
  if not sender then return nil, err end

  local function reader(...)
    return return_resume( coroutine.resume(sender, ...) )
  end

  return reader
end

function Socket:receive(...)
  if not self._reader then
    self._reader = start_reader(self._writer, self, ...)
  end
  return self._reader(...)
end

function Socket:getpeername()
end

--! @todo implement `send` method

end
-------------------------------------------------------------------

local function CLOSED(part)
  return function()
    return nil, 'closed', part or ''
  end
end

local function BuildSocket(t)
  local i, buffer = 1, Buffer.new('\r\n', false)

  return Socket:new(function(writer, self, pattern)
    -- we do not break this loop after send `closed`.
    -- So it possible read new data after that.
    -- It allows tests either user code try read data or not.
    while t[i] do
      local data, status, partial = t[i]
      if data == CLOSED then
        data = CLOSED()
        data, status, partial = data()
      elseif type(data) == 'function' then
        data, status, partial = data()
      elseif type(data) == 'table' then
        data, status, partial = data[1], data[2], data[3]
      end

      if data then
        buffer:append(data)
        repeat
          local size = buffer:size()
          data = buffer:read(pattern or '*l')
          local readed = size - buffer:size()
          if not data or readed == 0 then
            if not data then
              partial = buffer:read('*a')
            end
            pattern = writer(nil, 'timeout', partial or '')
          else
            pattern = writer(data)
          end
        until buffer:empty()
      elseif partial then
        pattern = writer(nil, status, partial)
      else
        pattern = writer(nil, status)
      end

      i = i + 1
    end

    while true do writer(nil, 'closed') end
  end)
end

return {
	CLOSED = CLOSED;
	Socket = Socket;
	BuildSocket = BuildSocket;
}