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
    
  end)

end)
