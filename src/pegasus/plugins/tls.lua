--- A plugin that enables TLS (https).
-- This plugin should not be used with Copas. Since Copas has native TLS support
-- and can handle simultaneous `http` and `https` connections. See the Copas example
-- to learn how to set that up.
local ssl = require("ssl")


local TLS = {}
TLS.__index = TLS


--- Creates a new plugin instance.
-- IMPORTANT: this must be the first plugin to execute before the client-socket is accessed!
-- @tparam sslparams table the data-structure that contains the properties for the luasec functions.
-- The structure is set up to mimic the LuaSec functions for the handshake.
-- @return the new plugin
-- @usage
-- local sslparams = {
--   wrap = table | context,    -- parameter to LuaSec 'wrap()'
--   sni = {                    -- parameters to LuaSec 'sni()'
--     names = string | table   --   1st parameter
--     strict = bool            --   2nd parameter
--   }
-- }
-- local tls_plugin = require("pegasus.plugins.tls"):new(sslparams)
function TLS:new(sslparams)
  sslparams = sslparams or {}
  assert(sslparams.wrap, "'sslparam.wrap' is a required option")

  return setmetatable({
    sslparams = sslparams
  }, TLS)
end

function TLS:newConnection(client)
  local params = self.sslparams

  -- wrap the client socket and replace it
  client = assert(ssl.wrap(client, params.wrap))

  if params.sni then
    assert(client:sni(params.sni.names, params.sni.strict))
  end

  if not client:dohandshake() then
    print"handshake failed"
    return false
  end
  print"running TLS"

  return client
end


return TLS
