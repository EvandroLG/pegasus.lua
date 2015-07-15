-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

-- Demonstrates the use of PegasusJs

local Pegasus = require 'pegasus'
local PegasusJs = require 'PegasusJs'

local server = Pegasus:new()

local js = PegasusJs.new("/comms")
assert(js.from_path)

local counter = 0
js:add({
      do_random = function(x)
         counter = counter + 1
         local r = math.random()
         return { cnt = counter, r_server = r, r_browser = x, r_total = x + r }
      end,
})

local script = js:script()

server:start(function (req, rep)
      local html = [[
<script>]] .. script ..
[[
function do_it() {
    var x = Math.random();
    var got = do_random(x);
    for(k in got){ document.getElementById(k).innerText = got[k]; }
    document.getElementById("js_calced").innerText = (x + got["r_server"]);
}
do_it();
</script>
<button onclick="do_it()">Do it</button>
<span id="cnt">Count not set</span>
<p>
<table>
<tr><td><span id="r_server"></span> + <span id="r_browser"></span></td>
     <td>= <span id="r_total"></span></td>
</tr>
<tr><td>javascript:<td>= <span id="js_calced"></span></td></tr>
</table>
]]
     if not js:respond(req, rep) then
        rep:addHeader('Content-Type', 'text/html'):write(html)
     end  -- else, `:respond` already did its job.
end)
