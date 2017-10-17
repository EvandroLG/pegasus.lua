local Request = require 'pegasus.request'

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

end

local function CLOSED(part)
  return function()
    return nil, 'closed', part or ''
  end
end

local function TIMEOUT(part)
  -- LuaSocket returns empty string as partial result
  return function()
    return nil, 'timeout', part or ''
  end
end

local function BuildSocket(t)
  local i = 1
  return Socket:new(function(writer, self, pattern)
    while t[i] do
      local data = t[i]
      if data == TIMEOUT then
        data = TIMEOUT()
        pattern = writer(data())
      elseif data == CLOSED then
        data = CLOSED()
        pattern = writer(data())
      elseif type(data) == 'function' then
        pattern = writer(data())
      elseif type(data) == 'table' then
        if data[3] ~= nil then
          pattern = writer(data[1],data[2],data[3])
        elseif data[2] ~= nil then
          pattern = writer(data[1],data[2])
        else
          pattern = writer(data[1])
        end
      else
        pattern = writer(t[i])
      end
      i = i + 1
    end

    while true do writer(nil, 'closed') end
  end)
end

local function BuildRequest(t)
  local client = BuildSocket(t)
  return Request:new(80, client)
end

describe('request #request', function()
  function getInstance(headers)
    local position = 1
    local param = {
      receive = function()
        if headers[position] ~= nil then
          local outcome = headers[position]
          position = position + 1

          return outcome
        end

        return nil
      end,

      getpeername = function(self) end
    }

    return Request:new(8080, param)
  end

  function length(dict)
    local count = 0
    for k in pairs(dict) do count = count + 1 end

    return count
  end

  describe('instance', function()
    local function verifyMethod(fn)
      local headers = { 'GET /index.html HTTP/1.1' }
      local request = getInstance(headers)
      local method = request[fn]

      assert.equal(type(method), 'function')
    end

    it('should exists constructor to request class', function()
      local headers = { 'GET /index.html HTTP/1.1' }
      local request = getInstance(headers)
      assert.equal(type(request), 'table')
    end)

    it('should exists path method', function()
      verifyMethod('path')
    end)

    it('should exists params method', function()
      verifyMethod('params')
    end)

    it('should exists method method', function()
      verifyMethod('method')
    end)

    it('should exists headers method', function()
      verifyMethod('headers')
    end)
  end)

  describe('methods', function()
    it('should returns correct filename when path is called', function()
      local headers = { 'GET /index.html HTTP/1.1', '' }
      local request = getInstance(headers)
      local result = request:path()

      assert.are.equal('/index.html', result)
    end)

    function verifyMethod(method)
      local headers = { method .. ' /index.html HTTP/1.1', '' }
      local request = getInstance(headers)
      local result = request:method()

      assert.are.equal(method, result)
    end

    it('should returns correct method - it is get - when method is called', function()
      verifyMethod('GET')
    end)

    it('should returns correct method - it is post - when method is called', function()
      verifyMethod('POST')
    end)

    it('should returns correct method - it is delete - when method is called', function()
      verifyMethod('DELETE')
    end)

    it('should returns correct method - it is put - when method is called', function()
      verifyMethod('PUT')
    end)

    it('should returns correct object when headers method is called', function()
      local headers = {'GET /Makefile?a=b&c=d HTTP/1.1', 'a: A', 'b: B', '', 'C=3', ''}
      local request = getInstance(headers)
      local result = request:headers()

      assert.equal(type(result), 'table')
      assert.equal(length(result), 2)
      assert.equal('A', result['a'])
      assert.equal('B', result['b'])
    end)

    it('should find value with = signal', function()
      local headers = { 'GET /Makefile?a=b= HTTP/1.1', 'a: A=', '' }
      local request = getInstance(headers)
      local result = request:headers()

      assert.table(result)
      assert.equal(length(result), 1)
    end)

    it('should handle empty path', function()
      local headers = { 'GET HTTP/1.1' }
      local request = getInstance(headers)

      assert.is_nil(request:method())
    end)

    it('should handle empty path with spaces', function()
      local headers = { 'GET   HTTP/1.1', '' }
      local request = getInstance(headers)

      assert.is_nil(request:method())
    end)

    it('should receive body by chunks', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Content-Length: 26',
        '',
        'abcdefghijkl', 'mnopqrstuvwxyz'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())
      assert.equal('26', request:headers()['Content-Length'])

      local body, status = request:receiveBody(12)
      assert.equal('abcdefghijkl', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.equal('mnopqrstuvwxyz', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)
    end)

    it('should receive full body', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Content-Length: 26',
        '',
        'abcdefghijklmnopqrstuvwxyz'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.equal('abcdefghijklmnopqrstuvwxyz', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)
    end)

    it('should receive full body with bigger size', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Content-Length: 26',
        '',
        'abcdefghijklmnopqrstuvwxyz'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody(1024)
      assert.equal('abcdefghijklmnopqrstuvwxyz', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)
    end)

    it('should receive chunked body by full chunks', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Transfer-Encoding: chunked',
        '',
        'c',
        'abcdefghijkl\r\n',
        'e',
        'mnopqrstuvwxyz\r\n',
        '0',
        '\r\n'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.equal('abcdefghijkl', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.equal('mnopqrstuvwxyz', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)
    end)

    it('should receive chunked body by partial chunks', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Transfer-Encoding: chunked',
        '',
        'c',
        'abcdef', 'ghijkl\r\n',
        'e',
        'mnopqrs', 'tuvwxyz\r\n',
        '0',
        '\r\n'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.equal('abcdef', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.equal('ghijkl', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.equal('mnopqrs', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.equal('tuvwxyz', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)

      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)
    end)

  end)

  describe('invalid requests', function()
    it('should not crash on invalid first line', function()
      local request, result
      assert.not_error(function()
        local headers = { 'garbage', nil }
        request = getInstance(headers)
        result = request:headers()
      end)

      assert.is_nil(request:method())
    end)
  end)

  describe('ip', function()
    it('should return a ip', function()
      local request = Request:new(8080, {
        getpeername = function(self)
          return '192.30.252.129'
        end
      })

      assert.equal(request.ip, '192.30.252.129')
    end)
  end)

  describe('port', function()
    it('should return a port', function()
      local request = Request:new(8080, {
        getpeername = function(self)
          return '192.30.252.129'
        end
      })

      assert.equal(request.port, 8080)
    end)
  end)

  describe('timeouts', function()
    it('should handle timeout when parse first line - 1', function()
      local request = BuildRequest{ TIMEOUT'GET', ' /index.html HTTP/1.1', '' }
      local _, err = assert.is_nil(request:method())
      assert.equal('timeout', err)
      assert.equal('GET', request:method())
    end)

    it('should handle timeout when parse first line - 2', function()
      local request = BuildRequest{TIMEOUT'GET /index.html ', TIMEOUT, 'HTTP/1.1', '' }

      -- first timeout
      local _, err = assert.is_nil(request:method())
      assert.equal('timeout', err)

      -- second timeout
      local _, err = assert.is_nil(request:method())
      assert.equal('timeout', err)

      assert.equal('GET', request:method())
    end)

    it('should handle timeout when receive body', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Content-Length: 26',
        '',
        TIMEOUT, -- #1
        TIMEOUT'abcdefg', -- #2
        TIMEOUT, -- #3
        TIMEOUT'hijklmnopqrstuvwxyz', -- #4
        '', -- #5
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      -- #1
      local body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('timeout', status)

      -- #2
      body, status = request:receiveBody()
      assert.equal('abcdefg', body, status)
      assert.is_nil(status)

      -- #3
      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('timeout', status)

      -- #4
      body, status = request:receiveBody()
      assert.equal('hijklmnopqrstuvwxyz', body, status)
      assert.is_nil(status)

      -- #5
      body, status = request:receiveBody()
      assert.is_nil(body)
      assert.equal('closed', status)
    end)

    it('should handle timeout when receive content length for chunk', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Transfer-Encoding: chunked',
        '',
        TIMEOUT, TIMEOUT'1', TIMEOUT, TIMEOUT'A', '',
        'abcdefghijklmnopqrstuvwxyz\r\n',
        '0', '\r\n'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- receive `1`
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- receive `2`
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- receive EOL for Content-Length
      body, status = request:receiveBody()
      assert.equal('abcdefghijklmnopqrstuvwxyz', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)
    end)

    it('should handle timeout when receive chunk', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Transfer-Encoding: chunked',
        '',
        '1A',
        TIMEOUT, TIMEOUT'abcdefghijkl', TIMEOUT, TIMEOUT'mnopqrstuvwxyz', TIMEOUT'\r\n',
        TIMEOUT'0', '',
        '\r\n'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      body, status = request:receiveBody()
      assert.equal('abcdefghijkl', body)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      body, status = request:receiveBody()
      assert.equal('mnopqrstuvwxyz', body)
      assert.is_nil(status)

      -- end of chunk
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- length for last chunk (0)
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)
    end)

  end)

  describe('closed', function()
    it('should handle closed when parse first line - 1', function()
      local request = BuildRequest{ CLOSED'GET', 'GET /index.html HTTP/1.1', '' }

      local _, err = assert.is_nil(request:method())
      assert.equal('closed', err)

      -- should not read any more data
      local _, err = assert.is_nil(request:method())
      assert.equal('closed', err)
      assert.equal('GET /index.html HTTP/1.1', request.client:receive())
    end)

    it('should handle closed when parse first line - 2', function()
      local request = BuildRequest{ CLOSED'GET /index.html HTTP/1.1\r\n', 'foo' }

      local _, err = assert.is_nil(request:method())
      assert.equal('closed', err)

      -- should not read any more data
      local _, err = assert.is_nil(request:method())
      assert.equal('closed', err)
      assert.equal('foo', request.client:receive())
    end)

    it('should handle closed when parse first line - 3', function()
      local request = BuildRequest{ 'GET /index.html HTTP/1.1', CLOSED'\r\n' }

      assert.equal('GET', request:method())
      assert.table(request:headers())

      assert.equal('GET', request:method())
      assert.table(request:headers())
    end)

    it('should handle closed when parse first line - 4', function()
      -- we have no end of request but just first header so we do not return headers
      local request = BuildRequest{ 'GET /index.html HTTP/1.1', CLOSED'a:b\r\n' }

      assert.equal('GET', request:method())
      assert.is_nil(request:headers())

      assert.equal('GET', request:method())
      assert.is_nil(request:headers())
    end)

    it('should handle closed when parse body', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Content-Length: 26',
        '',
        CLOSED'abcdefghijklmnopqrstuvwxyz'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())
    
      local body, status = request:receiveBody()
      assert.equal('abcdefghijklmnopqrstuvwxyz', body, status)
      assert.is_nil(status)
    
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)
    end)

    it('should handle closed when parse body and get not full message', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Content-Length: 26',
        '',
        CLOSED'abcdefghijkl', 'mnopqrstuvwxyz'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())
    
      local body, status = request:receiveBody()
      assert.equal('abcdefghijkl', body, status)
      assert.is_nil(status)
    
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)

      assert.equal('mnopqrstuvwxyz', request.client:receive())
    end)

    it('should handle closed when receive content length for chunk', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Transfer-Encoding: chunked',
        '',
        CLOSED'1', 'abcdef',
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)

      assert.equal('abcdef', request.client:receive())
    end)

    it('should handle closed when receive content for chunk', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1',
        'Transfer-Encoding: chunked',
        '',
        '1A',
        CLOSED'abcdef', 'ghijkl'
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      local body, status = request:receiveBody()
      assert.equal('abcdef', body, status)
      assert.is_nil(status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)

      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)

      assert.equal('ghijkl', request.client:receive())
    end)

  end)

end)
