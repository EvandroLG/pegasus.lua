[![pegasus.lua](http://evandrolg.github.io/pegasus.lua/pegasus.lua.svg)](http://evandrolg.github.io/pegasus.lua)

A http server to work with web applications written in Lua language [check the site](http://evandrolg.github.io/pegasus.lua).

## Installation

[![Join the chat at https://gitter.im/EvandroLG/pegasus.lua](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/EvandroLG/pegasus.lua?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
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

