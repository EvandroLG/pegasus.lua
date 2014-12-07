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
end)
