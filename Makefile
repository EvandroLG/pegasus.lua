.SILENT:

START_APP=spec/start_app.lua

run_example:
	lua example/app.lua

unit_test:
	busted

integration_test:
	lua $(START_APP) & busted spec/integration_test.lua
	ps aux | grep $(START_APP) | awk "{print $2}" \
	       | xargs kill

load_test:
	lua $(START_APP) & \
	ab -n 16000 -c 10 http://127.0.0.1:7070/ 
	ps aux | grep $(START_APP) | awk "{print $2}" \
	       | xargs kill

install_dependencies:
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
	luarocks install luacov
	luarocks install luafilesystem
