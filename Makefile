run:
	@lua lib/webserver.lua

test:
	@busted tests/*.lua

install_dependencies:
	. dependencies.sh
