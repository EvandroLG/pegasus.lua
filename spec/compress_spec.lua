local Compress = require 'pegasus.compress'

describe('compress', function()

  describe('instance', function()
    it('should exists new method', function()
      assert.equal(type(Compress.new), 'function')
    end)

    it('should exists processBodyData method', function()
      assert.equal(type(Compress.processBodyData), 'function')
    end)

    it('should accept a table to options attribute', function()
      local compress = Compress:new({ level=1 })
      assert.equal(type(compress.options), 'table')
    end)
  end)

  describe('processBodyData', function()
    function mockRequest()
      return {
        headers = function() 
          return {
            ['Accept-Encoding'] = 'gzip, deflate, sdch'
          }
        end 
      }
    end

    it('should add content-enconding = gzip if it is supported', function()
      local request = mockRequest()
      local key = nil
      local value = nil

      local response = {
        addHeader = function(obj, _key, _value)
          key = _key
          value = _value
        end
      }

      local compress = Compress:new({ level=1 })
      compress:processBodyData({}, false, request, response)

      assert.equal(key, 'Content-Encoding')
      assert.equal(value, 'gzip')
    end)

    it('should return data object when stayOpen is false', function()
      local data = {}
      local compress = Compress:new({ level=1 })
      local output = compress:processBodyData(data, true, mockRequest(), {})

      assert.equal(data, output)
    end)
  end)

end)
