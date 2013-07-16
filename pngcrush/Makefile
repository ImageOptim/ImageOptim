VERSION=1.7.65

.PHONY: all

all: pngcrush.c

pngcrush.c:
	curl -L http://downloads.sourceforge.net/project/pmt/pngcrush/$(VERSION)/pngcrush-$(VERSION).tar.gz | tar xz --strip-components=1 --exclude=Makefile
	-rm png.h pngconf.h 2>/dev/null
	patch -p1 < pngcrush.patch

clean:
	-rm *.c *.h 2>/dev/null

install:
