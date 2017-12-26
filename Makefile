.SILENT:

START_APP=test/start_app.lua

run_example:
	lua example/app.lua

unit_test:
	busted test/unit/

check:
	luacheck src/pegasus

start_app:
	lua $(START_APP) &

_integration_test:
	busted test/integration/

kill_server:
	ps aux | grep $(START_APP) | awk '{print $2}' | xargs kill &>/dev/null

integration_test: start_app _integration_test kill_server

_load_test:
	ab -n 15000 -c 10 http://127.0.0.1:7070/

load_test: start_app _load_test kill_server

build_docker:
	docker build -t pegasus .

run_docker:
	docker run -p 9090:9090 -it pegasus

install_dependencies:
	luarocks install luacheck
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
	luarocks install luafilesystem
	luarocks install lzlib
