-- logging

-- returns a LuaLogging compatible logger object.
-- If LuaLogging was already loaded, it returns the defaultlogger,
-- otherwise returns a stub. The stub has only no-op functions.

local ll = package.loaded.logging
if ll and type(ll) == "table" and ll.defaultLogger and
	tostring(ll._VERSION):find("LuaLogging") then
	-- default LuaLogging logger is available
	return ll.defaultLogger()
else
	-- just use a stub logger with only no-op functions
	local nop = function() end
	return setmetatable({}, {
		__index = function(self, key) self[key] = nop return nop end
	})
end
