VERSION=0.6.5
OPTIPNG_FILENAME=optipng-$(VERSION).tar.gz

build: all

all: png.h pngpriv.h

png.h pngpriv.h:
	@echo "Using pre-installed libpng source"

clean:
	test \! -e png.h || rm *.c png.h

install:

.PHONY: build all install clean
