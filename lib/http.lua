local http = {}
http._get = {}
http._post = {}
http.get = function(key)
  return http._get[key]
end

return http
