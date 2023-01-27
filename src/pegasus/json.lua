-- Wrapper library that supports multiple JSON libraries
local found, jsonlib

found, jsonlib = pcall(require, "cjson.safe") -- lua-cjson
if found then
  return setmetatable({
    -- decode is available
    -- encode is available
    -- null is available
    available = true,
    makeArray = function(t)
      assert(type(t) == "table", "expected a table")
      return setmetatable(t, jsonlib.array_mt)
    end,
    isArray = function(t)
      return getmetatable(t) == jsonlib.array_mt
    end,
    makeObject = function(t)
      assert(type(t) == "table", "expected a table")
      if getmetatable(t) == jsonlib.array_mt then
        setmetatable(t, nil)
      end
      return t
    end,
    isObject = function(t)
      return type(t) == "table" and getmetatable(t) ~= jsonlib.array_mt
    end,
  }, { __index = jsonlib })
end


found, jsonlib = pcall(require, "dkjson") -- dkjson
if found then
  local array_mt = { __jsontype = 'array' }
  local object_mt = { __jsontype = 'object' }
  return setmetatable({
    -- encode is available
    -- null is available
    -- decode is available; modify results to match other libs
    decode = function(value)
      local obj, _, err = jsonlib.decode(value, 1, jsonlib.null)
      if obj then
        return obj
      else
        return nil, err
      end
    end,
    available = true,
    makeArray = function(t)
      assert(type(t) == "table", "expected a table")
      return setmetatable(t, array_mt)
    end,
    isArray = function(t)
      return (getmetatable(t) or {}).__jsontype == 'array'
    end,
    makeObject = function(t)
      assert(type(t) == "table", "expected a table")
      return setmetatable(t, object_mt)
    end,
    isObject = function(t)
      return type(t) == "table" and (getmetatable(t) or {}).__jsontype ~= 'array'
    end,
  }, { __index = jsonlib })
end


found, jsonlib = pcall(require, "rapidjson") -- rapidjson
if found then
  local array_mt = { __jsontype = 'array' }
  local object_mt = { __jsontype = 'object' }
  return setmetatable({
    decode = function(value)
      return jsonlib.decode(value, 1, jsonlib.null)
    end,
    -- encode is available
    -- null is available
    available = true,
    makeArray = function(t)
      assert(type(t) == "table", "expected a table")
      return setmetatable(t, array_mt)
    end,
    isArray = function(t)
      return (getmetatable(t) or {}).__jsontype == 'array'
    end,
    makeObject = function(t)
      assert(type(t) == "table", "expected a table")
      return setmetatable(t, object_mt)
    end,
    isObject = function(t)
      return type(t) == "table" and (getmetatable(t) or {}).__jsontype ~= 'array'
    end,
  }, { __index = jsonlib })
end


local err = function()
  return nil, "no json library available, install 'lua-cjson', 'dkjson', or 'rapidjson'"
end

return {
  available = false,
  encode = err,
  decode = err,
  makeArray = err,
}
