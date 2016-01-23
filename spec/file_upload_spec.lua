local FileUpload = require 'pegasus.file_upload'

describe('file upload', function()
    describe('instance', function()
        local function verify_property(property, expected_type)
            local file_upload = FileUpload:new()
            assert.equal(type(file_upload[property]), expected_type)
        end

        it('should exists new method', function()
            assert.equal(type(FileUpload.new), 'function')
        end)

        it('should contains content_type_filter attribute', function()
            verify_property('content_type_filter', 'table')
        end)

        it('should contains content_type_discover attribute', function()
            verify_property('content_type_discover', 'table')
        end)

        it('should contains destination attribute', function()
            verify_property('destination', 'string')
        end)

        it('should contains min_body_size attribute', function()
            verify_property('min_body_size', 'nil')
        end)

        it('should contains max_body_size attribute', function()
            verify_property('max_body_size', 'nil')
        end)
    end)
end)
