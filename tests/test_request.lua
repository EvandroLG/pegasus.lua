package.path = package.path .. ';../?.lua'
local Request = require 'lib/request'


describe('require', function()
    describe('instance', function()
        function getInstance()
            local headers = { 'GET /index.html HTTP/1.1', 'A:B', 'C:D', nil , 'X=Y', '' }
            local err = {nil, nil, nil, nil, nil, 'error'}
            local param = {
                receive = function()
                    return headers[1], err[1]
                end
            }

            return Request:new(param)
        end

        function verifyMethod(fn)
            local request = getInstance()
            local method = request[fn]

            assert.equal(type(method), 'function')
        end

        it('should exists constructor to request class', function()
            local request = getInstance()

            assert.equal(type(request), 'table')
        end)

        it('should exists path method', function()
            verifyMethod('path')
        end)

        it('should exists params method', function()
            verifyMethod('params')
        end)

        it('should exists method method', function()
            verifyMethod('method')
        end)

        it('should exists headers method', function()
            verifyMethod('headers')
        end)

        it('should exists body method', function()
            verifyMethod('body')
        end)

        it('should exists form method', function()
            verifyMethod('form')
        end)
    end)
end)

-- local Request = require 'lib/request'

-- i =0
-- local headers = {'GET /Makefile?a=b&c=d HTTP/1.1', 'A:B', 'C:D', nil , 'X=Y', ''}
-- local err = {nil, nil, nil, nil, nil,'érro'}

-- local r = Request:new({receive=function () i=i + 1;return  headers[i], err[i]; end})

-- print(r:path())
-- print(r:params().a)
-- print(r:headers().A)
-- print(r:method())
-- print(r:body())
-- print(r:form().X)