VERSION=1.6.0

build: all

all: src/webp/encode.h

src/webp/encode.h:
	curl -sL https://github.com/webmproject/libwebp/archive/refs/tags/v$(VERSION).tar.gz | \
	  tar xz --strip-components=1 --exclude='Makefile*' \
	    'libwebp-$(VERSION)/src' 'libwebp-$(VERSION)/sharpyuv' \
	    'libwebp-$(VERSION)/imageio' \
	    'libwebp-$(VERSION)/examples' 'libwebp-$(VERSION)/COPYING'

clean:
	-rm -rf src sharpyuv imageio examples COPYING

install:

.PHONY: build all install clean
