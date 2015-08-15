
# zlib is not built here! It's included as part of libpng instead.

VERSION=0.6.3

build: all

all: zlib.h

zlib.h:
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/optipng-$(VERSION).tar.gz | tar xz --strip-components=3 --exclude=Makefile optipng-$(VERSION)/lib/zlib

clean:

install:

.PHONY: build all install clean
