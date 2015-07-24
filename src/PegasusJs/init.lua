local PegasusJs = {}

PegasusJs.__index = PegasusJs

-- from_path        Path used to send data across.
--                    Default: "PegasusJs"
-- funs             List of initial functions. The given table is used.
--                    Defaults to a new empty.
-- has_callbacks    Whether callbacks are provided for asynchronous use on
--                    the javascript side.
-- script_path      Path used, default `from_path .. "/index.js"` _must_ be under `from_path`
--                    user has to <script src=".."> this.
function PegasusJs.new(init_tab)
   init_tab.from_path = init_tab[1] or init_tab.from_path or "PegasusJs"
   init_tab[1] = nil
   init_tab.funs = init_tab.funs or {}
   init_tab.script_path = init_tab.script_path or (init_tab.from_path .. "/index.js")
   return setmetatable(init_tab, PegasusJs)
end

function PegasusJs:add(tab)
   for name, fun in pairs(tab) do self.funs[name] = fun end
end

local gen_js = require "PegasusJs.gen_js"
local callback_gen_js = require "PegasusJs.callback_gen_js"

-- As user, you dont need to touch it, it is put in
-- `self.from_path .. ."/index.js" defaultly, and `self.script_path` otherwise.
function PegasusJs:_script()
   local ret = gen_js.depend_js
   if self.has_callbacks then
      ret = ret .. callback_gen_js.depend_js
   end
   for name, _ in pairs(self.funs) do
      ret = ret .. gen_js.bind_js(self.from_path,  name)
      if self.has_callbacks then
         ret = ret .. callback_gen_js.bind_js(self.from_path,  name)
      end
   end
   return ret
end

local json = require "json"

function PegasusJs:respond(request, response)
   local n = #(self.from_path)
   assert(request.path)
   if string.sub(request.path, 1, n) == self.from_path then
      local _, j = string.find(request.path, "/", n + 2, true)
      local name = string.sub(request.path, n + 2, j and j - 1)
      local fun = self.funs[name]
      if fun then
         assert(request.post.d, "Didnt get response data?")
         local ret = fun(unpack(json.decode(request.post.d)))
         assert(type(ret) ~= "function", "Returned not-json-able, " .. request.path)
         local result = json.encode(ret)
         response:addHeader('Cache-Control', 'no-cache')  -- Dont cache, want it fresh.
         response:addHeader('Content-Type', 'text/json'):write(result)
         return true
      elseif request.path == self.script_path then
         response:addHeader('Cache-Control', 'no-cache') -- Suppose a end-data might be nicer.
         response:addHeader('Content-Type', 'text/javascript'):write(self:_script())
         return true
      else
         return "no_fun:" .. name
      end
   end
   -- If it doesnt apply, then the user comes with his/her own response.
end

return PegasusJs
