package.path = package.path .. ';../?.lua'
local Response = require 'lib/response'


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
        function verifyMakeHead(filename, statusCode, expectedMimetype)
            local response = Response:new({})
            local head = Response:makeHead(filename, statusCode)
            local expectedHead = string.gsub('HTTP/1.1 {{ STATUS_CODE }}', '{{ STATUS_CODE }}', statusCode)

            assert.truthy(string.find(head, expectedHead))
            assert.truthy(string.find(head, expectedMimetype))
        end

        it('should return a mimetype text/html and status code 404', function()
            verifyMakeHead('', '404', 'text/html')
        end)

        it('should return a mimetype text/css and status code 200', function()
            verifyMakeHead('style.css', '200', 'text/css')
        end)

        it('should return a mimetype application/javascript and status code 200', function()
            verifyMakeHead('script.js', '200', 'application/javascript')
        end)

        it('should return a mimetype text/html and status code 200', function()
            verifyMakeHead('index.html', '200', 'text/html')
        end)
    end)
end)
