.SILENT:

run_example:
	lua example/app.lua

test:
	for f in tests/*.lua; do busted "$$f"; done

install_dependencies:
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
