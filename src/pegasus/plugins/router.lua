--- A plugin that routes requests based on path and method.
-- Supports path parameters.
--
-- The `routes` table to configure the router is a hash-table where the keys are the path, and
-- the value is another hash-table. The second hash-table has the method as the key, and the
-- callbacks as the values.
-- Both hash-tables can have "`preFunction`" and "`postFunction`" entries,
-- which should have callbacks as values.
--
-- There are 5 callbacks (called in this order);
--
-- * the router `preFunction` callback is called first when there is a `prefix` match. It can
-- be used to do some validations, like path parameters, etc. It is defined on `router` level.
--
-- * the path `preFunction` callback is called when there is a `path` match. It can
-- be used to do some validations, like path parameters, etc. It is defined on `path` level.
--
-- * the `METHOD` (eg. `GET, `POST`, etc) this callback implements the specific method. It is defined
-- once for each supported method on the path. The special case is method "`*`" which is a catch-all.
-- The catch-all will be used for any method that doesn't have its own handler defined.
-- If omitted, the default catch-all will return a "405 Method Not Allowed" error.
--
-- * the path `postFunction` is called after the `METHOD` callback. This one is defined on `path` level.
--
-- * the router `postFunction` is called last. This one is defined on `router` level.
--
-- The callbacks have the following function signature; `stop = function(request, response)`.
-- If `stop` is truthy, request handling is terminated, no further callbacks will be called.
--
-- Path parameters can be defined in the path in curly braces; "`{variableName}`", and they will match
-- a single path segment. The values will be made available on the Request object as
-- `request.pathParameters.variableName`.
--
-- The API sub-path (without the prefix) is available as on the Request object as `request.routerPath`.
--
-- Route matching is based on a complete match (not prefix). And the order is based on the number
-- of path-parameters defined. Least number of parameters go first, such that static paths have
-- precedence over variables.
-- @usage
-- local routes = {
--   preFunction = function(req, resp)
--     local stop = false
--     -- this gets called before any path specific callback
--
--     if some_error then
--       resp:writeDefaultErrorMessage(400)
--       stop = true
--     end
--     return stop
--   end,
--
--
--   ["/my/{accountNumber}/{param2}/endpoint"] = { -- define path parameters
--
--     preFunction = function(req, resp)
--       local stop = false
--       -- this gets called before any method specific callback,
--       -- but after the path-preFunction
--       return stop
--     end,
--
--     GET = function(req, resp)
--       local stop = false
--       -- this implements the main GET logic
--       return stop
--     end,
--
--     POST = function(req, resp)
--       local stop = false
--       -- this implements the main POST logic
--       return stop
--     end,
--
--     ["*"] = function(req, resp)
--       local stop = false
--       -- this implements the wildcard, will handle any method except for the
--       -- GET/POST ones defined above.
--
--       -- If the wildcard is not defined, then a default one will be added which
--       -- only returns a "405 Method Not Allowed" error.
--       return stop
--     end,
--
--     postFunction = function(req, resp)
--       local stop = false
--       -- this gets called before after the method specific (or wildcard)
--       -- callback.
--
--       return stop
--     end,
--   },
--
--   ["/my/endpoint"] = function(req, resp)
--     local stop = false
--     -- this is a shortcut to create a wildcard-method, one callback
--     -- to handle any method for this path. Identical to:
--     -- ["/my/endpoint"] = { ["*"] = function(req, resp) ... end }
--     return stop
--   end,
--
--   postFunction = function(req, resp)
--     local stop = false
--     -- this gets called last.
--     return stop
--   end,
-- }
--
-- local router = Router:new {
--   prefix = "/api/1v0/",
--   routes = routes,
-- }

local Router = {}
Router.__index = Router

local noOpCallback = function()
  return false
end

local function methodNotAllowed(req, resp)
  resp:writeDefaultErrorMessage(405)
  return true -- "stop"
end

-- Parse the routes table.
local function parseRoutes(self, routes, prefix)
  local rts = {}
  local routerPreFunction = routes.preFunction
  local routerPostFunction = routes.postFunction

  for path, methods in pairs(routes) do
    if path ~= "preFunction" and path ~= "postFunction" then
      assert(path:sub(1,1) == "/", "paths must start with '/', got: " .. path)

      if type(methods) == "function" then
        methods = { ["*"] = methods } -- turn a single-function-shortcut into a table
      end

      methods["*"] = methods["*"] or methodNotAllowed

      local m = {}
      for method, callback in pairs(methods) do
        assert(type(callback) == "function", "expected callback to be a function, got: " .. type(callback))

        if method ~= "preFunction" and method ~= "postFunction" then
          assert(method == method:upper(), "expected method to be allcaps, got: " .. tostring(method))

          if method ~= "*" then
            m[method] = callback
          else
            -- a "catch all"; '*', so add metamethod to return the catch all
            setmetatable(m, {
              __index = function(self, key)
                return callback
              end
            })
          end
        end
      end

      local params = {}
      local pattern = path:gsub("{(%w+)}", function(name)
        params[#params+1] = name
        return "([^/]+)"
      end)
      pattern = "^" .. pattern .. "$"

      -- create and store the route
      rts[#rts+1] = {
        pattern = pattern,
        params = params,
        methods = m,
        routerPreFunction = routerPreFunction or noOpCallback,
        preFunction = methods.preFunction or noOpCallback,
        postFunction = methods.postFunction or noOpCallback,
        routerPostFunction = routerPostFunction or noOpCallback,
      }
    end
  end

  -- sort by number of parameters in the path, least go first
  table.sort(rts, function(a,b) return #a.params < #b.params end)
  return rts
end

--- Creates a new Router plugin instance.
-- @tparam options table the options table with the following fields;
-- @tparam[opt] options.prefix string the base path for all underlying routes.
-- @tparam options.routes table route definitions to be handled by this router plugin instance.
-- @return the new plugin
function Router:new(options)
  options = options or {}
  local plugin = {}

  local prefix = "/" .. (options.prefix or "") .. "/"
  while prefix:find("//") do
    prefix = prefix:gsub("//", "/")
  end
  plugin.prefix = prefix:sub(1, -2) -- drop trailing slash

  plugin.routes = parseRoutes(plugin, options.routes)

  setmetatable(plugin, Router)
  return plugin
end



function Router:newRequestResponse(request, response)
  local stop = false

  local path = request:path()
  if path:sub(1, #self.prefix) ~= self.prefix then
    return stop
  end
  path = path:sub(#self.prefix + 1, -1)

  for _, route in ipairs(self.routes) do
    local matches = { path:match(route.pattern) }
    if matches[1] ~= nil then
      -- we have a match
      local p = {}
      for i, paramName in ipairs(route.params) do
        p[paramName] = matches[i]
      end

      request.pathParameters = p
      request.routerPath = path -- the request path without the prefix

      stop = route.routerPreFunction(request, response)
      if stop then break end
      stop = route.preFunction(request, response)
      if stop then break end
      stop = route.methods[request:method()](request, response)
      if stop then break end
      stop = route.postFunction(request, response)
      if stop then break end
      route.routerPostFunction(request, response)
      stop = true
      break
    end
  end

  return stop
end

return Router
