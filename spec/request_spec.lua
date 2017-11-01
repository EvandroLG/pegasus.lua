local Request = require 'pegasus.request'

describe('require', function()
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

    it('should exists support_keep_alive method', function()
      verifyMethod('support_keep_alive')
    end)

    it('should exists reset method', function()
      verifyMethod('support_keep_alive')
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

    it('should handle keep-alive for HTTP/1.0 without Connection header', function()
      local headers = { 'GET / HTTP/1.0' }
      local request = getInstance(headers)
      local result = request:headers()
      assert.is_false(request:support_keep_alive())
    end)
  
    it('should handle keep-alive for HTTP/1.0 with Connection header', function()
      local headers = { 'GET / HTTP/1.0', 'Connection: keep-alive' }
      local request = getInstance(headers)
      local result = request:headers()
      assert.is_true(request:support_keep_alive())
    end)

    it('should handle keep-alive for HTTP/1.1 without Connection header', function()
      local headers = { 'GET / HTTP/1.1' }
      local request = getInstance(headers)
      local result = request:headers()
      assert.is_true(request:support_keep_alive())
    end)

    it('should handle keep-alive for HTTP/1.1 with Connection header', function()
      local headers = { 'GET / HTTP/1.1', 'Connection: close' }
      local request = getInstance(headers)
      local result = request:headers()
      assert.is_false(request:support_keep_alive())
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
end)
