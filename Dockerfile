FROM ubuntu:latest

MAINTAINER evandrolg <evandrolgoncalves@gmail.com>

RUN apt-get update -y && apt-get -y upgrade
RUN apt-get install -y libssl-dev build-essential libreadline-dev curl luarocks
RUN luarocks install mimetypes
RUN luarocks install luasocket
RUN luarocks install busted
RUN luarocks install luafilesystem
RUN luarocks install lzlib

ADD . /usr/local/pegasus/
WORKDIR /usr/local/pegasus
CMD ["make", "run_example"]
