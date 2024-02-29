--- A plugin that serves static content from a folder.

local mimetypes = require 'mimetypes'


local Files = {}
Files.__index = Files

--- Creates a new plugin instance.
-- The plugin will only respond to `GET` requests. The files will be served from the
-- `location` folder.
-- @tparam options table the options table with the following fields;
-- @tparam[opt="./"] options.location string the path to serve files from. Relative to the working directory.
-- @tparam[opt="index.html"] options.default string filename to serve for top-level without path. Use an empty
-- string to have none.
-- @return the new plugin
function Files:new(options)
  options = options or {}
  local plugin = {}

  local location = options.location or ""
  if location:sub(1,2) ~= "./" then
    -- make sure it's a relative path, forcefully!
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

  local default = options.default or "index.html"
  if default ~= "" then
    if default:sub(1,1) ~= "/" then
      default = "/" .. default
    end
  end
  plugin.default = default -- this is now a filename prefixed with a slash, or ""

  setmetatable(plugin, Files)
  return plugin
end



function Files:newRequestResponse(request, response)
  local stop = false

  local method = request:method()
  if method ~= "GET" and method ~= "HEAD" then
    return stop -- we only handle GET requests
  end

  local path = request:path()
  if path == '/' then
    if self.default ~= "" then
      response:redirect(self.default)
      stop = true
    end
    return stop -- no default set, so nothing to serve
  end

  local filename = self.location .. path

  stop = not not response:writeFile(filename, mimetypes.guess(filename) or 'text/html')

  return stop
end

return Files
