local function write_file(f, d)
  local f = assert(io.open(f, 'w+b'))
  f:write(d)
  f:close()
end

local function gzip(data)
  write_file('test.gz', data)
  local f = io.popen('gzip -d test.gz -c', 'r')
  local result
  if f then
    result = f:read('*a')
    f:close()
  end
  os.remove('test.gz')
  return result
end

describe('compress #compress', function()
  local Compress = require 'pegasus.compress'

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
    local function mockRequest()
      return {
        headers = function() 
          return {
            ['Accept-Encoding'] = 'gzip, deflate, sdch'
          }
        end 
      }
    end

    local function mockResponse()
      return {
        headers = {};
        addHeader = function(self,k,v)
          self.headers[k] = v
        end
      }
    end

    it('should not add content-enconding = gzip if it is not used', function()
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
      compress:processBodyData('', false, request, response)

      assert.is_nil(key)
      assert.is_nil(value)
    end)

    it('should return data object when stayOpen is false', function()
      local data = ''
      local compress = Compress:new({ level=1 })
      local output = compress:processBodyData(data, true, mockRequest(), {})

      assert.equal(data, output)
    end)

    it('should return data object when compress is not efficient', function()
      local data = 'Hello from Pegasus'
      local compress = Compress:new()
      local response = mockResponse()
      local output = compress:processBodyData(data, false, mockRequest(), response)

      assert.equal(data, output)
      assert.is_nil(response.headers['Content-Encoding'])
    end)

    it('should compress correct gzip format', function()
      local data = ('a'):rep(2 * 1024)
      local compress = Compress:new({ level = Compress.DEFAULT_COMPRESSION })
      local response = mockResponse()
      local output = compress:processBodyData(data, false, mockRequest(), response)
      assert.equal(data, gzip(output))
      assert.equal('gzip', response.headers['Content-Encoding'])
    end)

  end)

end)
