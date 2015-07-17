local lfs = require "lfs"
local mimetypes = require 'mimetypes'
local Cache = {}

Cache.files = {}
Cache.expireDelta = 1

function Cache:newRequestResponse(request, response)
  local metatable = getmetatable(response)

  function metatable:expires(time)
    self:addHeader('Expires', os.date('!%a, %d %b %Y %T GMT', os.time() + time))
  end
  function metatable:lastModified(time)
    self:addHeader('Last-Modified', os.date('!%a, %d %b %Y %T GMT', time))
  end
  function metatable:etag(etag)
    self:addHeader('etag', etag)
  end

  function metatable:redirectNotModified(etag)
    self:statusCode(304)
  end
end

function Cache:processFile(request, response, filename)
  local file_info = self.files[filename]
  if not file_info then
    file_info = {}
    response.filename = filename
    file_attrs = lfs.attributes(filename)
    file_info.attrs = file_attrs
    response:lastModified(file_attrs.change)
    response:expires(self.expireDelta)
    self.files[filename] = file_info
    return false
  else
    local last_modified = request:headers('if-modified-since')
    if last_modified then
      if last_modified == os.date('!%a, %d %b %Y %T GMT', file_info.attrs.change) then
        response:redirectNotModified()
        return false
      else
        response:contentType(response.headers['Content-Type']
          or mimetypes.guess(filename))
        file_info.content_type = response.headers['Content-Type']
        response:statusCode(200)
        response:write(file_info.data)
      end
      return true
    end
    response:statusCode(200)
    response:contentType(file_info.content_type)
    response.write(file_info.data)
    return true
  end
end

function Cache:processData(data, stayOpen, request, response)
  if response.filename == nil or response.filename == "" then
    return data
  end
  if not stayOpen then
    local file_info = self.files[response.filename]
    self.files[response.filename].data = data;
  end
  return data
end

return Cache
