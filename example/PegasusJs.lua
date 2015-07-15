-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

-- Demonstrates the use of PegasusJs

local Pegasus = require 'pegasus'
local PegasusJs = require 'PegasusJs'

local server = Pegasus:new("/comms")

js = PegasusJs.new()

local counter = 0
js:add({
      do_random = function(x)
         counter = counter + 1
         local r = random()
         return { cnt = counter, r_server = r, r_browser = x, r_total = x + r }
      end,
})

local script = js:script()

server:start(function (req, rep)
  --print('method=' .. req.method)
      local html = [[
<script>]] .. script ..
[[
function do_it() {
    var got = do_random(Math.random());
    for(k in got) { document.getElementByID(k).innerText = got[k]; }
}
</script>
<button onclick="do_it()">Do it</button>
<span id="cnt">Count not set</span>
<p>
<span id="r_server"></span> + <span id="r_browser"></span> = <span id="r_total"></span>
</p>
]]
     if not js:respond(req, rep) then
        rep:addHeader('Content-Type', 'text/html'):write(html)
     end  -- else, `:respond` already did its job.
end)
