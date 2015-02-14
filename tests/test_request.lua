package.path = package.path .. ';../?.lua'
local Request = require 'lib/request'


describe('require', function()
  function getInstance(headers)
    local err = {nil, nil, nil, nil, nil, 'error'}
    local param = {
      receive = function()
        return headers[1], err[1]
      end
    }

    return Request:new(param)
  end

  describe('instance', function()
    function verifyMethod(fn)
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
      local headers = { 'GET /index.html HTTP/1.1' }
      local request = getInstance(headers)
      local result = request:path()

      assert.are.equal('./index.html', result)
    end)

    function verifyMethod(method)
      local headers = { method .. ' /index.html HTTP/1.1' }
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
      local headers = {'GET /Makefile?a=b&c=d HTTP/1.1', 'A:1', 'B:2', nil , 'C=3', ''}
      local request = getInstance(headers)
      local result = request:headers()

      assert.equal(type(result), 'table')
      assert.equal(#result, 2)
      assert.equal('1', result['A'])
      assert.equal('2', result['B'])
    end)
  end)
end)
