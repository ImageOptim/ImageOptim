
VERSION=0.6.5
OPTIPNG_FILENAME=optipng-$(VERSION).tar.gz

png.h: /tmp/$(OPTIPNG_FILENAME)
	tar xz --strip-components=3 --exclude=Makefile /tmp/$(OPTIPNG_FILENAME) optipng-$(VERSION)/lib/libpng

/tmp/optipng.tar.gz:
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/$(OPTIPNG_FILENAME) -o /tmp/$(OPTIPNG_FILENAME)

clean:
	test \! -e png.h || rm *.c png.h

install:
	