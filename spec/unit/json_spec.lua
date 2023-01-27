describe("JSON", function()

  local lib_under_test
  local old_require = _G.require
  local json_libs = {
    ["cjson.safe"] = require "cjson.safe",
    dkjson = require "dkjson",
    rapidjson = require "rapidjson",
  }
  local clear_packages = function()
    for k, _ in pairs(json_libs) do
      package.loaded[k] = nil
    end
  end

  setup(function()

    _G.require = function(name)
      if name == lib_under_test then
        return json_libs[name]
      end
      if json_libs[name] then
        -- it's a json lib, but not the one we're testing, so return an error
        error("json lib '" .. name .. "' is not the one being tested")
      end
      -- it's not a json lib, so return the original require
      return old_require(name)
    end

    clear_packages()
  end)

  teardown(function()
    _G.require = old_require
  end)

  after_each(function()
    clear_packages()
  end)


  for lib_name, _ in pairs(json_libs) do
    describe("[" .. lib_name .. "]", function()

      local pjson, testdata

      setup(function()
        lib_under_test = lib_name
        pjson = require "pegasus.json"
      end)

      teardown(function()
        lib_under_test = nil
        pjson = nil
        package.loaded["pegasus.json"] = nil
      end)

      before_each(function()
        testdata = {
          object = {
            ["key1"] = "value1",
            ["key2"] = "value2",
          },
          emptyObject = pjson.makeObject{},
          array = {
            "value1",
            "value2",
          },
          emptyArray = pjson.makeArray{},
          boolean = true,
          number = 123,
          string = "hello world",
          null = pjson.null,
        }
      end)


      it("testing the right lib", function()
        assert.equal(json_libs[lib_name], getmetatable(pjson).__index)
      end)

      it("encodes testdata", function()
        local encoded, err = pjson.encode(testdata)
        assert.is.Nil(err)
        assert.is.string(encoded)
        assert.matches('"object":%w*{', encoded)
        assert.matches('"emptyObject":%w*{}', encoded)
        assert.matches('"array":%w*%[', encoded)
        assert.matches('"emptyArray":%w*%[%]', encoded)
        assert.matches('"boolean":%w*true', encoded)
        assert.matches('"number":%w*123', encoded)
        assert.matches('"string":%w*"hello world"', encoded)
        assert.matches('"null":%w*null', encoded)
      end)

      it("decodes testdata", function()
        local encoded, err = pjson.encode(testdata)
        assert.is.Nil(err)
        assert.is.string(encoded)
        local decoded, err = pjson.decode(encoded)
        assert.is.Nil(err)
        assert.same(testdata, decoded)
      end)

      it("validates an array", function()
        local arr = pjson.makeArray{}
        assert.is.True(pjson.isArray(arr))
        assert.is.False(pjson.isObject(arr))
      end)

      it("validates an object", function()
        local obj = pjson.makeObject{}
        assert.is.True(pjson.isObject(obj))
        assert.is.False(pjson.isArray(obj))
      end)

    end) -- describe single lib
  end -- for each lib

end)
