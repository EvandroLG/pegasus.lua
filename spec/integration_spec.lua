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

    assert.match('HTTP/1%.1 200 OK',         result)
    assert.match('Content%-Type: text/html', result)
    assert.match('Content%-Length: 16',      result)
  end)

  it('should return correct body', function()
    local result = executeCommand('curl')

    assert.match('Hello, Pegasus', result)
  end)
end)

