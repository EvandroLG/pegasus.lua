local Request = require 'pegasus.request'
local Utils   = require 'spec/utils'

local BuildSocket, CLOSED = Utils.BuildSocket, Utils.CLOSED

local function BuildRequest(t)
  local client = BuildSocket(t)
  return Request:new(80, client)
end

describe('request #request', function()
  local function getInstance(headers)
    for i = 1, #headers do
      headers[i] = headers[i] .. '\r\n'
    end
    return BuildRequest(headers)
  end

  local function length(dict)
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
        'GET /index.html HTTP/1.1\r\n',
        'Content-Length: 26\r\n',
        '\r\n',
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

    it('should receive full body - 1', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1\r\n',
        'Content-Length: 26\r\n',
        '\r\n',
        'abcdefghijklmnopqrstuvwxyz\r\n'
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

    it('should receive full body - 2', function()
      local request = BuildRequest{ ''
        .. 'GET /index.html HTTP/1.1\r\n'
        .. 'Content-Length: 26\r\n'
        .. '\r\n'
        .. 'abcdefghijklmnopqrstuvwxyz\r\n'
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
        'GET /index.html HTTP/1.1\r\n',
        'Content-Length: 26\r\n',
        '\r\n',
        'abcdefghijklmnopqrstuvwxyz\r\n'
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
        'GET /index.html HTTP/1.1\r\n',
        'Transfer-Encoding: chunked\r\n',
        '\r\n',
        'c\r\n',
        'abcdefghijkl\r\n',
        'e\r\n',
        'mnopqrstuvwxyz\r\n',
        '0\r\n',
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
        'GET /index.html HTTP/1.1\r\n',
        'Transfer-Encoding: chunked\r\n',
        '\r\n',
        'c\r\n',
        'abcdef', 'ghijkl\r\n',
        'e\r\n',
        'mnopqrs', 'tuvwxyz\r\n',
        '0\r\n',
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
      local request = BuildRequest{ 'GET', ' /index.html HTTP/1.1\r\n', '\r\n' }
      local _, err = assert.is_nil(request:method())
      assert.equal('timeout', err)
      assert.equal('GET', request:method())
    end)

    it('should handle timeout when parse first line - 2', function()
      local request = BuildRequest{'GET /index.html ', '', 'HTTP/1.1\r\n', '\r\n' }

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
        'GET /index.html HTTP/1.1\r\n',
        'Content-Length: 26\r\n',
        '\r\n',
        '',                    -- #1
        'abcdefg',             -- #2
        '',                    -- #3
        'hijklmnopqrstuvwxyz', -- #4
        '\r\n',                -- #5
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
        'GET /index.html HTTP/1.1\r\n',
        'Transfer-Encoding: chunked\r\n',
        '\r\n',
        '', '1', '', 'A', '\r\n',
        'abcdefghijklmnopqrstuvwxyz\r\n',
        '0\r\n', '\r\n'
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
        'GET /index.html HTTP/1.1\r\n',
        'Transfer-Encoding: chunked\r\n',
        '\r\n',
        '1A\r\n',
        '',               -- #1 - timout
        'abcdefghijkl',   -- #2 - chunk
        '',               -- #3 - timout
        'mnopqrstuvwxyz', -- #4 - chunk
        '\r\n',           -- #5 - timout
        '0',              -- #6 - timeout
        '\r\n',           -- #7.1
        '\r\n'            -- #7.2 - closed
      }
      assert.equal('GET', request:method())
      assert.table(request:headers())

      -- #1
      local body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- #2
      body, status = request:receiveBody()
      assert.equal('abcdefghijkl', body)
      assert.is_nil(status)

      -- #3
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- #4
      body, status = request:receiveBody()
      assert.equal('mnopqrstuvwxyz', body)
      assert.is_nil(status)

      -- #5 end of chunk
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- #6 length for last chunk (0)
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('timeout', status)

      -- #7
      body, status = request:receiveBody()
      assert.is_nil(body, status)
      assert.equal('closed', status)
    end)

  end)

  describe('closed', function()
    it('should handle closed when parse first line - 1', function()
      local request = BuildRequest{ CLOSED'GET', 'GET /index.html HTTP/1.1\r\n', '\r\n' }

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
      assert.equal('foo', request.client:receive('*a'))
    end)

    it('should handle closed when parse first line - 3', function()
      local request = BuildRequest{ 'GET /index.html HTTP/1.1\r\n', CLOSED'\r\n' }

      assert.equal('GET', request:method())
      assert.table(request:headers())

      assert.equal('GET', request:method())
      assert.table(request:headers())
    end)

    it('should handle closed when parse first line - 4', function()
      -- we have no end of request but just first header so we do not return headers
      local request = BuildRequest{ 'GET /index.html HTTP/1.1\r\n', CLOSED'a:b\r\n' }

      assert.equal('GET', request:method())
      assert.is_nil(request:headers())

      assert.equal('GET', request:method())
      assert.is_nil(request:headers())
    end)

    it('should handle closed when parse body', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1\r\n',
        'Content-Length: 26\r\n',
        '\r\n',
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
        'GET /index.html HTTP/1.1\r\n',
        'Content-Length: 26\r\n',
        '\r\n',
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

      assert.equal('mnopqrstuvwxyz', request.client:receive('*a'))
    end)

    it('should handle closed when receive content length for chunk', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1\r\n',
        'Transfer-Encoding: chunked\r\n',
        '\r\n',
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

      assert.equal('abcdef', request.client:receive('*a'))
    end)

    it('should handle closed when receive content for chunk', function()
      local request = BuildRequest{
        'GET /index.html HTTP/1.1\r\n',
        'Transfer-Encoding: chunked\r\n',
        '\r\n',
        '1A\r\n',
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

      assert.equal('ghijkl', request.client:receive('*a'))
    end)

  end)

end)
