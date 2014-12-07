package.path = package.path .. ';../?.lua'
local Response = require 'lib/response'


describe('response', function()
    describe('instance', function()
        it('should exists constructor to response class', function()
            local response = Response:new({})
            assert.equal(type(response), 'table')
        end)

        it('should exists processes method', function()
            local response = Response:new({})
            assert.equal(type(response.processes), 'function')
        end)

        it('should exists createContent method', function()
            local response = Response:new({})
            assert.equal(type(response.createContent), 'function')
        end)

        it('should exists makeHead method', function()
            local response = Response:new({})
            assert.equal(type(response.makeHead), 'function')
        end)
    end)
end)
