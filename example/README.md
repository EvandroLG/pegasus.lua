# Examples

to run the examples, execute them from the repository root. For example;

    cd pegasus.lua
    lua example/app.lua

# Copas example

This example requires LuaSec and Copas to enable https/tls. So ensure they
are installed.

Try this to generate the required certificates (might need some tweaking):

    cd pegasus.lua
    git clone https://github.com/lunarmodules/copas
    cd copas/tests/certs
    ./all.sh
    cd ../../..
    cp copas/tests/certs/serverAkey.pem ./example/
    cp copas/tests/certs/serverA.pem ./example/
    cp copas/tests/certs/rootA.pem ./example/
    rm -rf copas

    lua example/copas.lua

