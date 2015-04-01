local Pegasus = require 'pegasus'


describe('pegasus', function()
  describe('instance', function()
    it('should exists constructor to pegasus class', function()
      local server = Pegasus:new()
      assert.equal('table', type(server))
    end)

    it('should definer correct port', function()
      local expectedPort = '6060'
      local server = Pegasus:new(expectedPort)

      assert.equal(expectedPort, server.port)
    end)

    it('should has standard port set', function()
      local server = Pegasus:new()
      assert.equal('9090', server.port)
    end)
  end)
end)