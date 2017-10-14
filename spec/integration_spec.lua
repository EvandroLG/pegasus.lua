describe('integration', function()
  local port = '7070'
  local url = 'http://localhost:' .. port
  local toboolean = function(value)
    return not not value
  end

  local executeCommand = function(command)
    local handle = io.popen(command .. ' -s ' .. url)
    local result = handle:read('*a')
    handle:close()

    return result
  end

  it('should return correct headers', function()
    local result = executeCommand('curl --head')
    local isStatusOk = toboolean(result:match('HTTP/1.1 200 OK'))
    local isContentTypeOk = toboolean(result:match('Content%-Type: text%/html'))
    local isContentLengthOk = toboolean(result:match('Content%-Length: 16'))
    
    assert.is_true(isStatusOk)
    assert.is_true(isContentTypeOk)
    assert.is_true(isContentLengthOk)
  end)

  it('should return correct body', function()
    local result = executeCommand('curl')
    local isBodyOk = toboolean(result:match('Hello, Pegasus'))

    assert.is_true(isBodyOk)
  end)
end)

