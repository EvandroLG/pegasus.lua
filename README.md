# Pegasus.lua
Pegasus.lua is a http server to work with web applications written in Lua language.

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
#### Methods:
* <code>writeHead(number)</code> It creates the head; the function receives a status code by parameter
* <code>finish(string)</code> It creates the body; it accepts a content as parameter

```lua
  local Pegasus = require 'pegasus'

  local server = Pegasus:new('9090')

  server:start(function (req, rep)
    rep.writeHead(200).finish('hello pegasus world!')
  end)
```
