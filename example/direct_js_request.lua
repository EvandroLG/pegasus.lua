-- setup path to find the project source files of Pegasus
package.path = "./src/?.lua;./src/?/init.lua;"..package.path

-- Justs XMLHtttpRequest to get more information after loaded, from
-- client-side javascript.
-- IMO neater way to do it at https://github.com/o-jasper/PegasusJs

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
local poke_cnt = 0
server:start(function (req, rep)
      print(req.path)
      if req.path == "/" then
         local html = [[
<script>
function httpGet(url, data, callback) {
    var req = new XMLHttpRequest();
    req.open("POST", url, true);
    req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    req.setRequestHeader("Content-length", data.length);

    req.onreadystatechange = function() {
        if(req.readyState == 4 && req.status == 200) {
            callback(req.responseText);
        }
    }
    req.send("data=" + data);
}
var cnt = 0;
function pokewrite(data){
   cnt = cnt + 1;
   httpGet("/poke/", data, function(txt){ document.getElementById("ch").innerHTML = txt; })
   document.getElementById("cnt").innerText = cnt;
}
</script>
<button onclick="pokewrite('some data')">poke</button>
<p id="cnt"></p>
<p id="ch"></p>
]]
         rep:addHeader('Content-Type', 'text/html'):write(html)
         rep:addHeader('Expires: ', os.date("%c", os.time() + 4)) -- lasts a mere 4 seconds.
      elseif string.match(req.path, "^/poke") then
         poke_cnt = poke_cnt + 1
         local html = string.format("(%d)<br>", poke_cnt) ..
            "<b>headers</b><table>" .. html_table(req.headers) .. "</table>" ..
            "<b>methods</b><table>" .. html_table(req.methods or {}) .. "</table>" ..
            "<b>post</b><table>" .. html_table(req.post) .. "</table>" ..
            "<b>querystring</b><table>" .. html_table(req.querystring) .. "</table>" ..
            "<b>top</b><table>" .. html_table(req) .. "</table>" 
         rep:addHeader('Content-Type', 'text/html'):write(html)
         rep:addHeader('Cache-Control: no-cache')  -- Dont cache, want it fresh.
      else
         rep:addHeader('Content-Type', 'text/html'):write("aint got nothing here")
      end
end)
