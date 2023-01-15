local Pegasus = require 'pegasus'

describe('pegasus', function()
  describe('instance', function()
    it('should exists constructor to pegasus class', function()
      local server = Pegasus:new()
      assert.equal('table', type(server))
    end)

    it('should define a correct port', function()
      local expectedPort = '6060'
      local server = Pegasus:new { port = expectedPort }

      assert.equal(expectedPort, server.port)
    end)

    it('should has standard port set', function()
      local server = Pegasus:new()
      assert.equal('9090', server.port)
    end)

    it('should receive a location as parameter', function()
      local server = Pegasus:new { port = '8080', location = 'mimi/' }
      assert.equal('mimi/', server.location)
    end)

    it('should receive a location as plugins', function()
      local plugins = {}
      local server = Pegasus:new { port = '8080', location = 'mimi/', plugins = plugins }
      assert.equal(plugins, server.plugins)
    end)

  end)
end)
