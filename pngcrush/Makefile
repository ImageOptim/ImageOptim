VERSION=1.8.9
ARCHIVE=/tmp/pngcrush-$(VERSION).tar.gz

build: all

all: patched

$(ARCHIVE):
	curl -L -o $(ARCHIVE) http://downloads.sourceforge.net/project/pmt/pngcrush/old-versions/1.8/$(VERSION)/pngcrush-$(VERSION).tar.gz

pngcrush.c: pngcrush.patch $(ARCHIVE)
	tar xzf $(ARCHIVE) --strip-components=1 --exclude=Makefile
	-rm png.h pngconf.h 2>/dev/null

patched: pngcrush.c
	patch --forward -p1 < pngcrush.patch && touch patched

clean:
	-rm *.c *.h $(ARCHIVE) patched

install:

.PHONY: all build clean
