.SILENT:

START_APP=spec/start_app.lua

run_example:
	lua example/app.lua


unit_test:
	busted

start_app:
	lua $(START_APP) &

_integration_test:
	busted spec/integration_test.lua 

kill_server:
	ps aux | grep $(START_APP) | awk '{print $2}' | xargs kill &>/dev/null

integration_test: start_app _integration_test kill_server

_load_test:
	ab -n 15000 -c 10 http://127.0.0.1:7070/ 

load_test: start_app _load_test kill_server

install_dependencies:
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
	luarocks install luacov
	luarocks install luafilesystem
