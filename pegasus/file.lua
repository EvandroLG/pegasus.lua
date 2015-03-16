local File = {
  isDir = function(path)
    local file = io.open(path, 'r')

    if (file == nil) then return false end

    local ok, err, code = file:read(1)
    file:close()

    return code == 21
  end,

  exists = function(path)
    local file = io.open(path, 'r')

    if file ~= nil then
      io.close(file)
      return true
    else
      return false
    end
  end,

  pathJoin = function(path, file)
    return table.concat({ path, file }, '/')
  end,

  getIndex = function(self, path)
    filename = self.pathJoin(path, 'index.html')

    if not self.exists(filename) then
      filename = self.pathJoin(path, 'index.htm')
      if not filename then return nil end
    end

    return filename
  end,

  open = function(self, path)
    local filename = path

    if self.isDir(path) then
      filename = self.getIndex(self, path)
    end

    local file = io.open(filename, 'r')

    if file then
      return file:read('*all')
    end

    return nil
  end
}

return File
