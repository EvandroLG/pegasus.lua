local lfs = require "lfs"
local mimetypes = require 'mimetypes'

local Cache = {}

Cache.files = {}
Cache.expireDelta = 1

function Cache:new()
  local cache= {}
  self.__index = self
  return setmetatable(cache, self)
end

function Cache:alterRequestResponseMetaTable(Request, Response)
  function Response:expires(time)
    self:addHeader('Expires', os.date('!%a, %d %b %Y %T GMT', os.time() + time))
  end

  function Response:lastModified(time)
    self:addHeader('Last-Modified', os.date('!%a, %d %b %Y %T GMT', time))
  end

  function Response:etag(etag)
    self:addHeader('etag', etag)
  end

  function Response:redirectNotModified(etag)
    self:statusCode(304)
  end

  function Request:ifModifiedSince()
     return self:headers()['If-Modified-Since']
  end
end

function Cache:processFile(request, response, filename)
  local fileinfo = self.files[filename]

  if fileinfo then
    local last_modified = request:ifModifiedSince()

    if last_modified and last_modified == os.date('!%a, %d %b %Y %T GMT', fileinfo.attrs.change) then
      response:redirectNotModified()
      response:sendOnlyHeaders(false, '');
      return true
    end
  else
    fileinfo = {}
    response.filename = filename
    file_attrs = lfs.attributes(filename)
    fileinfo.attrs = file_attrs
    response:lastModified(file_attrs.change)
    response:expires(self.expireDelta)
    self.files[filename] = fileinfo

    return false
  end
end


function Cache:processBodyData(data, stayOpen, request, response)
  if response.filename == nil or response.filename == "" then
    return data
  end

  if not stayOpen then
    local fileinfo = self.files[response.filename]
    self.files[response.filename].data = data;
  end

  return data
end

return Cache
