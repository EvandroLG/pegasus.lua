-- Callback version of `gen_js`

local Public = {}

Public.depend_js = [[
function httpGet_callback(url, data, callback) {
    var req = new XMLHttpRequest();
    req.open("POST", url, true);

    req.setRequestHeader('Content-Type', 'text/json')
    req.setRequestHeader("Content-length", data.length + 5);
    
    req.onreadystatechange = function() {
        if(req.readyState == 4 && req.status == 200) {
            callback(req.responseText);
        }
    }
    req.send("data=" + data);
}
]]

-- Returns the string implementing it on the javascript side.
function Public.bind_js(url, name)
   return string.format([[
function callback_%s(args, callback){
    var pass_callback(responseText) {
        callback(JSON.decode(responseText))
    }
    httpGet_callback("%s/%s/", JSON.encode(args), pass_callback);
}
]],
      name, url, name)
end

return Public
