[![pegasus.lua](http://evandrolg.github.io/pegasus.lua/pegasus.lua.svg)](http://evandrolg.github.io/pegasus.lua)

A http server to work with web applications written in Lua language [check the site](http://evandrolg.github.io/pegasus.lua).

[![Build
Status](https://travis-ci.org/EvandroLG/pegasus.lua.svg?branch=master)](https://travis-ci.org/EvandroLG/pegasus.lua)
[![HuBoard
badge](http://img.shields.io/badge/Hu-Board-7965cc.svg)](https://huboard.com/EvandroLG/pegasus.lua)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/EvandroLG/pegasus.lua?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Installation
To install Pegasus.lua, run:
```sh
$ luarocks install pegasus
```

## How does it work?
Follow an example:
```lua
local pegasus = require 'pegasus'

local server = pegasus:new({
  port='9090',
  location='example/root'
})

server:start(function (request, response)
  print "It's running..."
end)
```

## Features
- Compatible with Linux, Mac and Windows systems
- Easy API
- Support Lua >= 5.1
- Native support for HTTP Streaming, aka chunked responses. [Check how it works](https://github.com/EvandroLG/pegasus.lua/blob/master/example/app_stream.lua).
- Native plugin to compress responses using the "gzip" method

## API
### Request
#### Properties
* `path` A string with the request path
* `headers` A table with all the headers data
* `method` The output is the request method as a string ('GET', 'POST', etc)
* `querystring` It returns a dictionary with all the GET parameters
* `post` It returns a dictionary with all the POST parameters
* `ip` It returns the client's ip
* `port` It returns the port where Pegasus is running

### Response
#### Methods
* `addHeader(string:key, string:value)` Adds a new header
* `addHeaders(table:headers)` It adds news headers
* `statusCode(number:statusCode, string:statusMessage)` It adds a Status Code
* `contentType(string:value)` Adds a value to Content-Type field
* `write(string:body)` It creates the body with the value passed as
  parameter
* `writeFile(string:file)` It creates the body with the content of the
  file passed as parameter

```lua
local pegasus = require 'pegasus'

local server = pegasus:new({ port='9090' })

server:start(function (req, rep)
  rep:addHeader('Date', 'Mon, 15 Jun 2015 14:24:53 GMT'):write('hello pegasus world!')
end)
```

## Native Plugin
* pegasus.compress
```lua
local Pegasus = require 'pegasus'
local Compress = require 'pegasus.compress'

local server = Pegasus:new({
  plugins = { Compress:new() }
})

server:start()
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

