# Pegasus.lua
Pegasus.lua is a basic http server to work with Lua language.

![pegasus.lua](http://evandrolg.github.io/pegasus.lua/pegasus.lua.svg)

## How it work?
Follow an example:
```lua
  local Pegasus = require 'pegasus'

  local server = Pegasus:new('9090')

  server:start(function (require, response) 
    print "It's running..."
  end)
```

## API
### Require:
#### Properties:
* <code>path</code> A string with the request path
* <code>headers</code> A table with all the headers data
* <code>method</code> The output is the request method as a string ('GET', 'POST', etc)
* <code>querystring</code> It return a dictionary with all the GET parameters
* <code>post</code> It return a dictionary with all the POST parameters

### Response:
In development
