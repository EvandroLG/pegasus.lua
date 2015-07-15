# Javascript bindings,
You load this completely separately to Pegasus, and feed the
`request` and `response` `server:start` to the `:respond`
method of this thing. If it returns `nil`/`false`, then you can
do your own thing.

Depends on `json` package, there is an example in `examples/PegasusJs.lua`.

### Api:

`local PegasusJs = require "PegasusJs"` to get the lib, assuming it is
available to `package.path`.

`local pjs = PegasusJs.new(from_path, fun_table, has_callbacks)`
makes a new one, `from_path` the path of which all sub-paths are used.
`fun_table` is an initial set of functions. `{}` if `nil`.
`has_callbacks` whether it has callbacks.

`pjs:add(tab)` where tab is a table mapping javascript names to functions.

`pjs:script()` returns the string that is the javascript side bindings 
that implement it on that side. The page in some way must include this
javascript.

`pjs:respond(request, response)` returns false if the path was itis supposed
to ignore(i.e, not in from_path earlier. true if the path corresponds to a
function correctly, and "incorrect" or perhaps some description otherwise.

#### Provides to javascript:
If `name` has a function, then `name(...)` is the same function in javascript.

If callbacks are enabled, then `callback_<name>(args, callback_function)` is
*also* provided.

### Files:

`src/PegasusJs/` has `gen_js.lua`, where javascript is generated.
`callback_gen_js` the callback version. `init.lua` is the main file
implementing `:respond` and otherwise putting things together.

## TODO

* Make callbacks/regular optional? i.e.
  `{function, what}` with `what` `"callback"` or `"function"` or `"both"`

* Lack of tests, just the example right now.

* Lack of lua rock.
