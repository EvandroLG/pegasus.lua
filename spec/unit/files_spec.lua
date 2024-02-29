describe("Files plugin", function()

  local Files = require "pegasus.plugins.files"



  describe("instantiation", function()

    local options = {}
    local plugin = Files:new(options)

    it("should return a table", function()
      assert.is.table(plugin)
    end)


    it("should have a default location; '.'", function()
      assert.is.equal(".", plugin.location)
    end)


    it("should have a default; '/index.html'", function()
      assert.is.equal("/index.html", plugin.default)
    end)

  end)



  describe("invocation", function()

    local redirect_called, writeFile_called
    local request = {}
    local response = {
      redirect = function(self, ...) redirect_called = {...} end,
      writeFile = function(self, ...) writeFile_called = {...} return self end,
      -- finish = function(self, ...) end,
      -- setHeader = function(self, ...) end,
      -- setStatusCode = function(self, ...) end,
    }

    before_each(function()
      redirect_called = nil
      writeFile_called = nil
    end)


    it("handles GET", function()
      stub(request, "path", function() return "/some/file.html" end)
      stub(request, "method", function() return "GET" end)
      local stop = Files:new():newRequestResponse(request, response)
      assert.is.True(stop)
      assert.is.Nil(redirect_called)
      assert.are.same({
        "./some/file.html",
        "text/html"
      }, writeFile_called)
    end)

    it("handles HEAD", function()
      stub(request, "path", function() return "/some/file.html" end)
      stub(request, "method", function() return "HEAD" end)
      local stop = Files:new():newRequestResponse(request, response)
      assert.is.True(stop)
      assert.is.Nil(redirect_called)
      assert.are.same({
        "./some/file.html",
        "text/html"
      }, writeFile_called)
    end)

    it("doesn't handle POST", function()
      stub(request, "path", function() return "/some/file.html" end)
      stub(request, "method", function() return "POST" end)
      local stop = Files:new():newRequestResponse(request, response)
      assert.is.False(stop)
      assert.is.Nil(redirect_called)
      assert.is.Nil(writeFile_called)
    end)

    it("doesn't handle PUT", function()
      stub(request, "path", function() return "/some/file.html" end)
      stub(request, "method", function() return "PUT" end)
      local stop = Files:new():newRequestResponse(request, response)
      assert.is.False(stop)
      assert.is.Nil(redirect_called)
      assert.is.Nil(writeFile_called)
    end)

    it("redirects GET /", function()
      stub(request, "path", function() return "/" end)
      stub(request, "method", function() return "GET" end)
      local stop = Files:new():newRequestResponse(request, response)
      assert.is.True(stop)
      assert.are.same({
        "/index.html"
      }, redirect_called)
      assert.is.Nil(writeFile_called)
    end)

    it("serves from specified location", function()
      stub(request, "path", function() return "/some/file.html" end)
      stub(request, "method", function() return "GET" end)
      local stop = Files:new({ location = "./location" }):newRequestResponse(request, response)
      assert.is.True(stop)
      assert.is.Nil(redirect_called)
      assert.are.same({
        "./location/some/file.html",
        "text/html"
      }, writeFile_called)
    end)

    it("forces location to be relative", function()
      stub(request, "path", function() return "/some/file.html" end)
      stub(request, "method", function() return "GET" end)
      local stop = Files:new({ location = "/location" }):newRequestResponse(request, response)
      assert.is.True(stop)
      assert.is.Nil(redirect_called)
      assert.are.same({
        "./location/some/file.html",
        "text/html"
      }, writeFile_called)
    end)

  end)

end)
