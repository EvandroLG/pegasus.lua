[![pegasus.lua](http://evandrolg.github.io/pegasus.lua/pegasus.lua.svg)](http://evandrolg.github.io/pegasus.lua)

An http server to work with web applications written in Lua language [check the site](https://evandrolg.github.io/pegasus.lua).

[![Unix build](https://img.shields.io/github/actions/workflow/status/EvandroLG/pegasus.lua/unix_build.yml?branch=master&label=Unix%20build&logo=linux)](https://github.com/EvandroLG/pegasus.lua/actions/workflows/unix_build.yml)
[![Lint](https://github.com/EvandroLG/pegasus.lua/workflows/Lint/badge.svg)](https://github.com/EvandroLG/pegasus.lua/actions/workflows/lint.yml)
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

Or try the [included examples](example/README.md).

## Features

- Compatible with Linux, Mac and Windows systems
- Easy API
- Support Lua >= 5.1
- Native support for HTTP Streaming, aka chunked responses. [Check how it works](https://github.com/EvandroLG/pegasus.lua/blob/master/example/app_stream.lua).
- Native plugin to compress responses using the "gzip" method

## API

### Parameters

* `host:string` Host address where the application will run. By default it uses `localhost`
* `port:string` The port where the application will run. By default it's `9090`
* `location:string` Path used by Pegasus to search for the files. By default it's the root
* `plugins:table` List with plugins
* `timeout:number` It's a timeout for estabilishing a connection with the server

### Request

#### Properties

* `path:string` A string with the request path
* `headers:table` A table with all the headers data
* `method:function` The output is the request method as a string ('GET', 'POST', etc)
* `querystring:string` It returns a dictionary with all the GET parameters
* `ip:string` It returns the client's ip
* `port:number` It returns the port where Pegasus is running

### Response

#### Methods

* `addHeader(string:key, string:value)` Adds a new header
* `addHeaders(table:headers)` It adds news headers
* `statusCode(number:statusCode, string:statusMessage)` It adds a Status Code
* `contentType(string:value)` Adds a value to Content-Type field
* `write(string:body)` It creates the body with the value passed as
  parameter
* `writeDefaultErrorMessage(statusCode: string, message:body)` It sets an HTTP status code and writes an error message to the response
* `writeFile(string:file)` It creates the body with the content of the
  file passed as parameter
* `post():table` It returns a dictionary with all the POST parameters
* `redirect(location:string, temporary:boolean):` Makes an HTTP redirect to a new location. The status code is set to 302 if temporary is true and false otherwise.

```lua
local pegasus = require 'pegasus'

local server = pegasus:new({ port='9090' })

server:start(function (req, rep)
  rep:addHeader('Date', 'Mon, 15 Jun 2015 14:24:53 GMT'):write('hello pegasus world!')
end)
```

## Native Plugin

* pegasus.plugins.compress

```lua
local Pegasus = require 'pegasus'
local Compress = require 'pegasus.plugins.compress'

local server = Pegasus:new({
  plugins = { Compress:new() }
})

server:start()
```

* pegasus.plugins.downloads

```lua
local Pegasus = require 'pegasus'
local Downloads = require 'pegasus.plugins.downloads'

local server = Pegasus:new({
  plugins = {
    Downloads:new {
      prefix = "downloads",
      stripPrefix = true,
    },
  }
})

server:start()
```

* pegasus.plugins.tls

```lua
local Pegasus = require 'pegasus'
local Tls = require 'pegasus.plugins.tls'

local server = Pegasus:new({
  plugins = {
    TLS:new {
      wrap = {
        mode = "server",
        protocol = "any",
        key = "./serverAkey.pem",
        certificate = "./serverA.pem",
        cafile = "./rootA.pem",
        verify = {"none"},
        options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"},
      },
      sni = nil,
    },,
  }
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
$ make unit_test
```

