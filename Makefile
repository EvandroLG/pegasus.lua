.SILENT:

START_APP=spec/start_app.lua

.PHONY: run_example
run_example:
	lua example/app.lua

.PHONY: test
test: unit_test integration_test

.PHONY: unit_test
unit_test:
	busted spec/unit/

.PHONY: check
check:
	luacheck .

.PHONY: start_app
start_app:
	lua $(START_APP) &

.PHONY: _integration_test
_integration_test:
	busted spec/integration/

.PHONY: kill_server
kill_server:
	pkill -f $(START_APP)

.PHONY: integration_test
integration_test: start_app _integration_test kill_server

.PHONY: _load_test
_load_test:
	wrk http://127.0.0.1:7070/

.PHONY: load_test
load_test: start_app _load_test kill_server

.PHONY: install
install:
	luarocks install luacheck
	luarocks install mimetypes
	luarocks install luasocket
	luarocks install busted
	luarocks install luafilesystem
	luarocks install lzlib
