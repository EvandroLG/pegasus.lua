--- A plugin that allows to download files via a browser.
local Downloads = {}
Downloads.__index = Downloads

--- Creates a new plugin instance.
-- The plugin will only respond to `GET` requests. The files will be served from the
-- same `location` setting as defined in the `Handler`. The `prefix` is a virtual folder
-- that triggers the plugin, but will be removed from the filepath if `stripPrefix` is truthy.
-- If `stripPrefix` is falsy, then it should be a real folder.
-- @tparam options table the options table with the following fields;
-- @tparam[opt="./"] options.location string the path to serve files from. Relative to the working directory.
-- @tparam[opt="downloads/"] options.prefix string the path prefix that triggers the plugin
-- @tparam options.stripPrefix bool whether to strip the prefix from the file path when looking
-- for the file in the filesystem. Defaults to `false`, unless `options.prefix` is omitted,
-- then it defaults to `true`.
-- @return the new plugin
function Downloads:new(options)
  options = options or {}
  local plugin = {}

  local location = options.location or ""
  if location:sub(1,2) ~= "./" then
    if location:sub(1,1) == "/" then
      location = "." .. location
    else
      location = "./" .. location
    end
  end
  if location:sub(-1,-1) == "/" then
    location = location:sub(1, -2)
  end
  plugin.location = location  -- this is now a relative path, without trailing slash

  local prefix = options.prefix
  if prefix then
    plugin.stripPrefix = not not options.stripPrefix
  else
    prefix = "downloads/"
    if options.stripPrefix == nil then
      plugin.stripPrefix = true
    else
      plugin.stripPrefix = not not options.stripPrefix
    end
  end

  prefix = "/" .. prefix .. "/"
  while prefix:find("//") do
    prefix = prefix:gsub("//", "/")
  end
  plugin.prefix = prefix -- this is now the prefix, with pre+post fixed a / (or a single slash)

  setmetatable(plugin, Downloads)

  return plugin
end

function Downloads:newRequestResponse(request, response)
  local stop = false
  if request:method() ~= "GET" then
    return stop -- we only handle GET requests
  end

  local path = request:path()
  if path:find(self.prefix, nil, true) ~= 1 then
    return stop -- doesn't match our prefix
  end

  local filename = path
  if self.stripPrefix then
    filename = path:sub(#self.prefix, -1)
  end

  stop = not not response:sendFile(self.location .. filename)
  return stop
end


return Downloads
