.SILENT:

run_example:
	lua example/app.lua

test:
	busted tests/*.lua

install_dependencies:
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
