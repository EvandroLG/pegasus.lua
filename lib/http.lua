http = {}
http._get = nil
http._post = nil
http.parser = function(key)
    return http._get[key]
end

return http