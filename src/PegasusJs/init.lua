local PegasusJs = {}

PegasusJs.__index = PegasusJs

function PegasusJs.new(from_path, fun_table, callback)
   return setmetatable(
      { from_path = from_path, funs = fun_table or {}, callback_any=callback },
      PegasusJs
   )
end

function PegasusJs:add(tab)
   for name, fun in pairs(tab) do self.funs[name] = fun end
end

local gen_js = require "PegasusJs.gen_js"
local callback_gen_js = require "PegasusJs.callback_gen_js"

function PegasusJs:script()
   local ret = gen_js.depend_js
   if self.callback then
      ret = ret .. callback_gen_js.depend_js_callback
   end
   for name, _ in pairs(self.funs) do
      ret = ret .. gen_js.bind_js(self.from_path,  name)
      if self.callback then
         ret = ret .. callback_gen_js.bind_js(self.from_path,  name)
      end
   end
   return ret
end

local json = require "json"

function PegasusJs:respond(request, response)
   local n = #(self.from_path)
   if string.sub(request.path, 1, n) == self.from_path then
      local _, j = string.find(request.path, "/", n, true)
      local name = string.sub(request.path, n, j)
      local fun = self.funs[name]
      if fun then
         --request.headers
         local result = json.encode(fun(json.decode(data)))
         response:addHeader('Content-Type', 'text/json'):write(result)
         response:addHeader('Cache-Control: no-cache')  -- Dont cache, want it fresh.         
         return true
      else
         return "no_fun:" .. name
      end
   end
   -- If it doesnt apply, then the user comes with his/her own response.
end


return PegasusJs
