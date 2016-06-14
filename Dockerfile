FROM ubuntu:15.04

MAINTAINER evandrolg <evandrolgoncalves@gmail.com>

RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    luarocks \
    inotify-tools \
    lsof

RUN luarocks install luasocket
RUN luarocks install busted
RUN luarocks install mimetypes
RUN luarocks install luafilesystem
RUN luarocks install lzlib
