local File = {
  isDir = function(path)
    local file = io.open(path, 'r')

    if (file == nil) then return false end

    local ok, err, code = file:read(1)
    file:close()

    return code == 21
  end,

  pathJoin = function(path, file)
    return table.concat({ path, file }, '/')
  end,


 open = function(self, path)
    local filename = path

    if self.isDir(path) then
      filename = self.pathJoin(path, 'index.html')
    end

    local file = io.open(filename, 'r')

    if file then
        return file:read('*all')
    end

    return nil
  end
}

return File
