-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

-- Demonstrates the use of PegasusJs

local Pegasus = require 'pegasus'
local PegasusJs = require 'PegasusJs'

local server = Pegasus:new()

local js = PegasusJs.new{"/comms", has_callbacks=true}
assert(js.from_path)

local counter = 0
js:add({
      do_random = function(x)
         counter = counter + 1
         local r = math.random()
         return { cnt = counter, r_server = r, r_browser = x, r_total = x + r }
      end,
})

server:start(function (req, rep)
      local html = [[
<script type="text/javascript" src="/comms/index.js"></script>
<script>
function do_it() {
    var x = Math.random();
    var got = do_random(x);
    for(k in got){ document.getElementById(k).innerText = got[k]; }
    document.getElementById("js_calced").innerText = (x + got["r_server"]);
}
function callback_do_it() {
    var x = Math.random();
    callback_do_random([x], function(got) {
      for(k in got){ document.getElementById(k).innerText = got[k]; }
      document.getElementById("js_calced").innerText = (x + got["r_server"]);
    })
}
</script>
<button onclick="do_it()">Do it</button>
<button onclick="callback_do_it()">Callback do it</button>
<span id="cnt">Count not set</span>
<p>
<table>
<tr><td><span id="r_server"></span> + <span id="r_browser"></span></td>
     <td>= <span id="r_total"></span></td>
</tr>
<tr><td>javascript:<td>= <span id="js_calced"></span></td></tr>
</table>
<script>
// In programs, I avoid doing things in a special way in the first time.
do_it();
</script>
]]
      if not js:respond(req, rep) then
         rep:addHeader('Content-Type', 'text/html'):write(html)
      end  -- else, `:respond` already did its job.
end)
