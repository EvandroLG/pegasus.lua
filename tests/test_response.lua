package.path = package.path .. ';../?.lua'
local Response = require 'lib/response'


describe('response', function()
    describe('instance', function()
        it('should exists constructor to response class', function()
            local response = Response:new({})
            assert.equal(type(response), 'table')
        end)

        it('should exists process method', function()
        end)

        it('should exists createContent method', function()
        end)

        it('should exists makeHead method', function()
        end)
    end)
end)
