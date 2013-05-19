VERSION=1.7.56

.PHONY: all

all: pngcrush.c

pngcrush.c:
	curl -L http://downloads.sourceforge.net/project/pmt/pngcrush/old-versions/1.7/$(VERSION)/pngcrush-$(VERSION).tar.gz | tar xz --strip-components=1 --exclude=Makefile
	-rm png.h pngconf.h 2>/dev/null
	patch -p2 < pngcrush.patch

clean:
	-rm *.c *.h 2>/dev/null

install:
