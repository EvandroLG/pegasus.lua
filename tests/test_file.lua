local File = require 'pegasus.file'

describe('file', function()
  describe('methods', function()
    local verifyMethod = function(method)
      assert.equal('function', type(File[method]))
    end

    it('should have isDir method', function()
      verifyMethod('isDir')
    end)

    it('should have pathJoin method', function()
      verifyMethod('pathJoin')
    end)

    it('should have open method', function()
      verifyMethod('open')
    end)
  end)

  describe('isDir', function()
    local verifyOutput = function(path, expected)
      local output = File.isDir(path)
      assert[expected](output)
    end

    it('should return false when the path is a file', function()
      verifyOutput('tests/fixtures/index.html', 'falsy')
    end)

    it('should return false when the path does not exist', function()
      verifyOutput('tests/fixtures/contact.html', 'falsy')
    end)

    it('should return true when the path is a directory', function()
      verifyOutput('tests/fixtures/', 'truthy')
    end)
  end)

  describe('pathJoin', function()
    it('should return path and file concatenated with a bar', function()
      local output = File.pathJoin('tests/fixtures', 'index.html')
      assert.equal(output, 'tests/fixtures/index.html')
    end)
  end)

  describe('open', function()
    it('should return nil when file does not exist', function()
      local output = File.open(File, 'tests/fixtures/contact.html')
      assert.equal(output, nil)
    end)

    local verifyContent = function(path, expectedOutput)
      local output = File.open(File, path)
      isOk = string.find(output, expectedOutput)

      assert.truthy(isOk)
    end

    it('should return correct content from file passed as parameter', function()
      verifyContent('tests/fixtures/index.html', 'Hello, Pegasus!')
    end)

    it('should return index.html content when path passed as parameter is a directory', function()
      verifyContent('tests/fixtures/', 'Hello, Pegasus!')
    end)
  end)

  describe('exists', function()
    local verifyOutput = function(path, method)
      local output = File.exists(path)
      assert[method](output)
    end

    it('should return false when file that was passed as parameter does not exist', function()
      verifyOutput('tests/fixtures/index.htm', 'falsy')
    end)

    it('shoud return true when file that was passed as parameter exist', function()
      verifyOutput('tests/fixtures/index.html', 'truthy')
    end)
  end)
end)
