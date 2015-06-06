local Response = require 'pegasus.response'


describe('response', function()
  describe('instance', function()
    function verifyMethod(method)
      local response = Response:new({})
      assert.equal(type(response[method]), 'function')
    end

    it('should exists constructor to response class', function()
      local response = Response:new({})
      assert.equal(type(response), 'table')
    end)

    it('should exists processes method', function()
      verifyMethod('processes')
    end)

    it('should exists createContent method', function()
      verifyMethod('createContent')
    end)

    it('should exists makeHead method', function()
      verifyMethod('makeHead')
    end)
  end)

  describe('make head', function()
    function verifyMakeHead(filename, statusCode, message, expectedMimetype)
      local response = Response:new({})
      local head = Response:makeHead(statusCode, filename)
      local expectedHead = string.gsub('HTTP/1.1 {{ MESSAGE }}', '{{ MESSAGE }}', message)

      assert.truthy(string.find(head, expectedHead))
      assert.truthy(string.find(head, expectedMimetype))
    end

    it('should return a mimetype text/html and status code 404', function()
      verifyMakeHead('', 404, '404 Not Found', 'text/html')
    end)

    it('should return a mimetype text/css and status code 200', function()
      verifyMakeHead('style.css', 200, '200 OK', 'text/css')
    end)

    it('should return a mimetype application/javascript and status code 200', function()
      verifyMakeHead('script.js', 200, '200 OK', 'application/javascript')
    end)

    it('should return a mimetype text/html and status code 200', function()
      verifyMakeHead('index.html', 200, '200 OK', 'text/html')
    end)

    it('should return a content length', function()
      local head = Response:makeHead(200, 'index.html');
      assert.truthy(string.find(head, 'Content%-Length: 0'))
    end)
  end)

  describe('response content', function()
    local DEFAULT_ERROR_MESSAGE = [[
      <!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN'
          'http://www.w3.org/TR/html4/strict.dtd'>
      <html>
      <head>
          <meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
          <title>Error response</title>
      </head>
      <body>
          <h1>Error response</h1>
          <p>Error code: {{ CODE }}</p>
          <p>Message: {{ MESSAGE }}.</p>
      </body>
      </html>
    ]]

    function verifyCreateContentWithError(filename, content, statusCode, expectedErrorCode, expectedMessage)
      local response = Response:new()
      local result = response:createContent(filename, content, statusCode)

      assert.truthy(string.find(result, expectedErrorCode))
      assert.truthy(string.find(result, expectedMessage))
    end

    it('should return a page with 404 as status code', function()
      local expectedErrorCode = '<p>Error code: 404</p>'
      local expectedMessage = '<p>Message: Not Found.</p>'

      verifyCreateContentWithError('index.html', DEFAULT_ERROR_MESSAGE, 404, expectedErrorCode, expectedMessage)
    end)

    it('should return a page with 500 as status code', function()
      local expectedErrorCode = '<p>Error code: 500</p>'
      local expectedMessage = '<p>Message: Internal Server Error.</p>'

      verifyCreateContentWithError('index.html', DEFAULT_ERROR_MESSAGE, 500, expectedErrorCode, expectedMessage)
    end)

    it('should return a content correct with status code 200', function()
      local response = Response:new()
      local result = response:createContent('index.html', 'hello lua world!', 200)

      assert.truthy(string.find(result, 'hello lua world!'))
    end)
  end)
end)
