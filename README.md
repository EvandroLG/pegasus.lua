[![pegasus.lua](http://evandrolg.github.io/pegasus.lua/pegasus.lua.svg)](http://evandrolg.github.io/pegasus.lua)

simple HTTP server written in Lua to work with web applications. [check the site](http://evandrolg.github.io/pegasus.lua).

## Installation
To install Pegasus.lua, run:
```sh
$ luarocks install pegasus
```

## How does it work?
Follow an example:
```lua
local pegasus = require 'pegasus'

local server = pegasus:new('9090')

server:start(function (request, response)
  print "It's running..."
end)
```

## API
### Request
#### Properties
* `path` A string with the request path
* `headers` A table with all the headers data
* `method` The output is the request method as a string ('GET', 'POST', etc)
* `querystring` It returns a dictionary with all the GET parameters
* `post` It returns a dictionary with all the POST parameters

### Response
#### Methods
* `writeHead(number)` It creates the head; the function receives a status code by parameter
* `finish(string)` It creates the body; it accepts a content as parameter

```lua
local pegasus = require 'pegasus'

local server = pegasus:new('9090')

server:start(function (req, rep)
  rep.writeHead(200).finish('hello pegasus world!')
end)
```

## Contributing

### Install Dependencies

```sh
$ make install_dependencies
```

### Running tests

```sh
$ make test
```

