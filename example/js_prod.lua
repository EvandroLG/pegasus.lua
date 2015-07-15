-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

local Pegasus = require 'pegasus'

local server = Pegasus:new()

local function html_table(tab)
   local html = ""
   for k,v in pairs(tab) do
      html = html .. string.format("<tr><td>%s =</td><td>%s</td></tr>", k,v)
   end
   return html
end

-- _basic_ asking information from the server by javascript.
-- TODO cachers inbetween assume they can keep it, afaict.
local poke_cnt = 0
server:start(function (req, rep)
      if req.path == "/" then
         local html = [[
<script>
function httpGet(url, request) {
    var req = new XMLHttpRequest();
    req.open("GET", url, false);
    req.send(request);
    return req.responseText;
}
var cnt = 0;
function pokewrite(data){
   cnt = cnt + 1;
   document.getElementById("ch").innerHTML = httpGet("/poke", data);
   document.getElementById("cnt").innerText = cnt;
}
</script>
<button onclick="pokewrite()">poke</button>
<p id="cnt"></p>
<p id="ch"></p>
]]
         rep:addHeader('Content-Type', 'text/html'):write(html)
         rep:addHeader('Expires', os.date("%c", os.time() + 4)) -- lasts a mere 4 seconds.
      elseif req.path == "/poke" then
         poke_cnt = poke_cnt + 1
         local html = string.format("(%d)<br>", poke_cnt) ..
            "<b>headers</b><table>" .. html_table(req.headers) .. "</table>" ..
            "<b>methods</b><table>" .. html_table(req.methods or {}) .. "</table>" ..
            "<b>post</b><table>" .. html_table(req.post) .. "</table>"
         rep:addHeader('Content-Type', 'text/html'):write(html)
         rep:addHeader('Cache-Control', 'no-cache')  -- Dont cache, want it fresh.
      else
         rep:addHeader('Content-Type', 'text/html'):write("aint got nothing here")
      end
end)
