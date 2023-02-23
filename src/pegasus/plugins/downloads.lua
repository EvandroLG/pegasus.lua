--- A plugin that allows to download files via a browser.
local Downloads = {}
Downloads.__index = Downloads

--- Creates a new plugin instance.
-- The plugin will only respond to `GET` requests. The files will be served from the
-- same `location` setting as defined in the `Handler`. The `prefix` is a virtual folder
-- that triggers the plugin, but will be removed from the filepath if `stripPrefix` is truthy.
-- If `stripPrefix` is falsy, then it should be a real folder.
-- @tparam options table the options table with the following fields;
-- @tparam[opt="downloads/"] options.prefix string the path prefix that triggers the plugin
-- @tparam options.stripPrefix bool whether to strip the prefix from the file path when looking
-- for the file in the filesystem. Defaults to `false`, unless `options.prefix` is omitted,
-- then it defaults to `true`.
-- @return the new plugin
function Downloads:new(options)
  options = options or {}
  local plugin = {}

  if not options.prefix then
    plugin.prefix = "downloads/"
    if options.stripPrefix == nil then
      plugin.stripPrefix = true
    else
      plugin.stripPrefix = not not options.stripPrefix
    end
  else
    plugin.prefix = options.prefix
    plugin.stripPrefix = not not options.stripPrefix
  end

  plugin.prefix = "/" .. plugin.prefix .. "/"
  while plugin.prefix:find("//") do
    plugin.prefix = plugin.prefix:gsub("//", "/")
  end

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

  local location = response._writeHandler.location or ""
  local filename = path
  if self.stripPrefix then
    filename = path:sub(#self.prefix + 1, -1)
  end

  stop = not response:sendFile('.' .. location .. filename)
  return stop
end


return Downloads
