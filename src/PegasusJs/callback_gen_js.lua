-- Callback version of `gen_js`

local Public = {}

Public.depend_js = [[
function httpGet_callback(url, data, callback) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        //alert(req.readyState + " ... " + req.status);
        if(req.readyState == 4 && req.status == 200) {
            callback(req.responseText);
        }
    }

    req.open("POST", url, true);

    req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    req.setRequestHeader("Content-length", data.length + 2);
    req.setRequestHeader("Cache-Control", "no-cache");

    req.send("d=" + data);
}
]]

-- Returns the string implementing it on the javascript side.
function Public.bind_js(url, name)
   return string.format([[
function callback_%s(arg_list, callback){
    //alert("work..." + arg_list);
    httpGet_callback("%s/%s/", JSON.stringify(arg_list), 
                     function(responseText) {
                       callback(JSON.parse(responseText));
                     });
}
]],
      name, url, name)
end

return Public
