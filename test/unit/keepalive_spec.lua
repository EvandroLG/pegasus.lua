local Request   = require 'pegasus.request'
local Response  = require 'pegasus.response'
local Handler   = require 'pegasus.handler'
local KeepAlive = require 'pegasus.keepalive'
local Utils     = require 'test/utils'

local counter, BuildSocket, CLOSED = Utils.counter, Utils.BuildSocket, Utils.CLOSED

local function BuildHandler(t, callback)
  local keepalive = KeepAlive:new{
    requests = 2;
  }
  local handler = Handler:new(callback, nil, {keepalive})
  local client = BuildSocket(t)

  return handler, client, keepalive
end

describe('keepalive #keepalive', function()
  describe('basic', function()
    it('should use same connection for 2 requests', function()
      local called, handler, client = counter()
      handler, client = BuildHandler({
        'GET /index.html HTTP/1.1\r\n\r\n';
        'GET /index.html HTTP/1.1\r\n\r\n';
      }, function(req, res)
        called()
        assert.equal(client, req.client)
      end)

      handler:processRequest(80, client)
      assert.equal(2, called(0))
      assert.is_true(client._closed)
    end)

    it('should close connection after timeout', function()
      local called, handler, client = counter()
      handler, client = BuildHandler({
        'GET /index.html HTTP/1.1\r\n\r\n';
        '';
        'GET /index.html HTTP/1.1\r\n\r\n';
      }, function(req, res)
        called()
        assert.equal(client, req.client)
      end)

      handler:processRequest(80, client)
      assert.equal(1, called(0))
      assert.is_true(client._closed)
    end)

    it('should not execute more than 2 requests', function()
      local called, handler, client = counter()
      handler, client = BuildHandler({
        'GET /index.html HTTP/1.1\r\n\r\n';
        'GET /index.html HTTP/1.1\r\n\r\n';
        'GET /index.html HTTP/1.1\r\n\r\n';
      }, function(req, res)
        called()
        assert.equal(client, req.client)
      end)

      handler:processRequest(80, client)
      assert.equal(2, called(0))
      assert.is_true(client._closed)
    end)
  end)
end)
