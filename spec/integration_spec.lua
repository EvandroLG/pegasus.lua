describe('integration', function()
  local port = '7070'
  local url = 'http://localhost:' .. port

  local executeCommand = function(command)
    local handle = io.popen(command .. ' -s ' .. url)
    local result = handle:read('*a')
    handle:close()

    return result
  end

  it('should return correct headers', function()
    local result = executeCommand('curl --head')

    assert.match(result, 'HTTP/1%.1 200 OK')
    assert.match(result, 'Content%-Type: text/html')
    assert.match(result, 'Content%-Length: 16')
  end)

  it('should return correct body', function()
    assert.match(executeCommand('curl'), 'Hello, Pegasus')
  end)
end)

