local Response = require 'pegasus.response'


describe('response', function()
  describe('instance', function()
    function verifyMethod(method)
      local response = Response:new({close=function () end})
      assert.equal(type(response[method]), 'function')
    end

    it('should exists constructor to response class', function()
      local response = Response:new({close=function () end})
      assert.equal(type(response), 'table')
    end)

    it('should exists addHeader method', function()
      verifyMethod('addHeader')
    end)

    it('should exists addHeaders method', function()
      verifyMethod('addHeaders')
    end)

    it('should exists contentType method', function()
      verifyMethod('contentType')
    end)

    it('should exists statusCode method', function()
      verifyMethod('statusCode')
    end)

    it('should exists write method', function()
      verifyMethod('write')
    end)

    it('should exists writeFile method', function()
      verifyMethod('writeFile')
    end)
  end)

  describe('write', function()
    local verifyOutput = function(statusCode, expectedBody)
      local client = {
        send = function(self, content)
          local isOk = not not string.match(content, expectedBody)
          assert.is_true(isOk)
        end,
        close = function () end
      }

      local response = Response:new(client)
      response:statusCode(statusCode)
      response:write(expectedBody)
    end

    local verifyErrorOutput = function(statusCode)
      local expectedBody = 'Error code: ' .. tostring(statusCode)
      verifyOutput(statusCode, expectedBody)
    end

    it('should deliver proper content with status 200', function()
      verifyOutput(200, 'Hello Pegasus World!')
    end)

    it('should deliver error page with status 404', function()
      verifyErrorOutput(404)
    end)

    it('should deliver error page with status 500', function()
      verifyErrorOutput(500)
    end)
  end)

  describe('add header', function()
    it('should add correct header passed as a parameter', function()
      local response = Response:new({})
      response:addHeader('Content-Length', 100)

      assert.equal(response.headers['Content-Length'], 100)
    end)

    it('should do a merge with headers already passed', function()
      local response = Response:new({})
      response:addHeader('Content-Length', 100)
      response:addHeader('Content-Type', 'text/html')
      response:addHeaders({
        ['Age'] = 15163,
        ['Connection'] = 'keep-alive'
      })
      local headers = response.headers

      assert.equal(headers['Content-Length'], 100)
      assert.equal(headers['Content-Type'], 'text/html')
      assert.equal(headers['Age'], 15163)
      assert.equal(headers['Connection'], 'keep-alive')
    end)
  end)

  describe('status code', function()
    local verifyStatus = function(statusCode, statusText, expectedMessage)
      local response = Response:new({})
      response:statusCode(statusCode, statusText)
      local expectedStatus = 'HTTP/1.1 ' .. tostring(statusCode)
      local isStatusCorrect = not not string.match(response.headFirstLine, expectedStatus)
      local isMessageCorrect = not not string.match(response.headFirstLine, expectedMessage)

      assert.is_true(isStatusCorrect)
      assert.is_true(isMessageCorrect)
    end

    it('should add status code passed as a parameter', function()
      verifyStatus(200, nil, 'OK')
    end)

    it('should add status and message passed as parameters', function()
      verifyStatus(200, 'Perfect!', 'Perfect!')
    end)
  end)

  describe('set default headers', function()
    it('should define a default value to content-type and content-length', function()
      local response = Response:new()
      response.closed = true
      response:_setDefaultHeaders()

      assert.equal('text/html', response.headers['Content-Type'])
      assert.equal(0, response.headers['Content-Length'])
    end)

    it('should keep value previously set', function()
      local response = Response:new()
      response:addHeader('Content-Type', 'application/javascript')
      response:addHeader('Content-Length', 100)
      response:_setDefaultHeaders()

      assert.equal('application/javascript', response.headers['Content-Type'])
      assert.equal(100, response.headers['Content-Length'])
    end)

  end)

  describe('write', function()
    local verifyClient = function(expectedBody, body, header)
      local client = {
        send = function(obj, content)
          for key, value in pairs(header) do
            assert.is_true(not not string.match(content, value))
          end

          local isBodyCorrect = not not string.match(content, expectedBody)
          assert.is_true(isBodyCorrect)
        end,
        close = function () end
      }

      local response = Response:new(client)
      response:addHeaders(header)
      response:write(body)
    end

    it('should call send method passing body', function()
      verifyClient("It's a content", "It's a content", {})
    end)

    it('should call send method passing head and body both', function()
      verifyClient("It's a content", "It's a content", { ['Content-Type'] = 'text/javascript' })
    end)
  end)


  --describe('make head', function()
    --function verifyMakeHead(filename, statusCode, message, expectedMimetype)
      --local response = Response:new({})
      --local head = response:statusCode(statusCode)
      --local expectedHead = string.gsub('HTTP/1.1 {{ MESSAGE }}', '{{ MESSAGE }}', message)

      --assert.truthy(string.find(head, expectedHead))
      --assert.truthy(string.find(head, expectedMimetype))
    --end

    --it('should return a mimetype text/html and status code 404', function()
      --verifyMakeHead('', 404, '404 Not Found', 'text/html')
    --end)

    --it('should return a mimetype text/css and status code 200', function()
      --verifyMakeHead('style.css', 200, '200 OK', 'text/css')
    --end)

    --it('should return a mimetype application/javascript and status code 200', function()
      --verifyMakeHead('script.js', 200, '200 OK', 'application/javascript')
    --end)

    --it('should return a mimetype text/html and status code 200', function()
      --verifyMakeHead('index.html', 200, '200 OK', 'text/html')
    --end)

    --it('should return a content length', function()
      --local response = Response:new({})
      --local head = response:addHeader('Content-Length', 0)

      --assert.truthy(string.find(head, 'Content%-Length: 0'))
    --end)
  --end)

  --describe('response content', function()
    --local DEFAULT_ERROR_MESSAGE = [[
      --<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN'
          --'http://www.w3.org/TR/html4/strict.dtd'>
      --<html>
      --<head>
          --<meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
          --<title>Error response</title>
      --</head>
      --<body>
          --<h1>Error response</h1>
          --<p>Error code: {{ CODE }}</p>
          --<p>Message: {{ MESSAGE }}.</p>
      --</body>
      --</html>
    --]]

    --function verifyCreateContentWithError(filename, content, statusCode, expectedErrorCode, expectedMessage)
      --local response = Response:new()
      --local result = response:createContent(filename, {}, content, statusCode)

      --assert.truthy(string.find(result, expectedErrorCode))
      --assert.truthy(string.find(result, expectedMessage))
    --end

    --it('should return a page with 404 as status code', function()
      --local expectedErrorCode = '<p>Error code: 404</p>'
      --local expectedMessage = '<p>Message: Not Found.</p>'

      --verifyCreateContentWithError('index.html', DEFAULT_ERROR_MESSAGE, 404, expectedErrorCode, expectedMessage)
    --end)

    --it('should return a page with 500 as status code', function()
      --local expectedErrorCode = '<p>Error code: 500</p>'
      --local expectedMessage = '<p>Message: Internal Server Error.</p>'

      --verifyCreateContentWithError('index.html', DEFAULT_ERROR_MESSAGE, 500, expectedErrorCode, expectedMessage)
    --end)

    --it('should return a content correct with status code 200', function()
      --local response = Response:new()
      --local result = response:createContent('index.html', {}, 'hello lua world!', 200)

      --assert.truthy(string.find(result, 'hello lua world!'))
    --end)
  --end)
end)
