
# zlib is not built here! It's included as part of libpng instead.

VERSION=1.3.2

build: all

all: zlib.h

zlib.h:
	curl -sL https://github.com/madler/zlib/archive/refs/tags/v$(VERSION).tar.gz | \
	  tar xz --strip-components=1 --exclude='Makefile*' \
	    'zlib-$(VERSION)/*.c' 'zlib-$(VERSION)/*.h'

clean:
	-rm -f *.c *.h

install:

.PHONY: build all install clean
