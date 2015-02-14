.SILENT:

run_example:
	lua example/app.lua

test:
	echo "\nrequest test:"
	busted tests/test_request.lua
	echo "\nresponse test:"
	busted tests/test_response.lua
	echo "\npegasus test:"
	busted tests/test_pegasus.lua

install_dependencies:
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
