
VERSION=0.6.4

png.h:
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/optipng-$(VERSION).tar.gz | tar xz --strip-components=3 --exclude=Makefile optipng-$(VERSION)/lib/libpng
	
clean:
	test \! -e png.h || rm *.c png.h

install:
	