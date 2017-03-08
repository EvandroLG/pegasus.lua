-- Generating javascript for the bindings.
-- callback_gen_js is the asynchronous version.

local Public = {}

-- Javascript it depends on.
Public.depend_js = [[
function httpGet(url, data) {
    var req = new XMLHttpRequest();
    req.open("POST", url, false);

    req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    req.setRequestHeader("Content-length", data.length + 2);
    req.setRequestHeader("Cache-Control", "no-cache");
    
    req.send("d=" + data);

    return req.responseText;
}

function jsonCall(url, args) {
    return JSON.parse(httpGet(url, JSON.stringify(args)))
}
]]

-- Returns the string implementing it on the javascript side.
function Public.bind_js(url, name)
   return string.format([[
function %s(){
    return jsonCall("%s/%s/", [].slice.call(arguments));
}
]],
      name, url, name)
end

return Public
