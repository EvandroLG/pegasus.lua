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
        it('should return a mimetype text/html and a status code 404', function ()
            local response = Response:new({})
            local head = Response:makeHead('', '404')

            assert.truthy(string.find(head, 'HTTP/1.1 404'))
            assert.truthy(string.find(head, 'text/html'))
        end)
    end)
end)
