VERSION=1.8.9
ARCHIVE=/tmp/pngcrush-$(VERSION).tar.gz

build: all

all: pngcrush.c

$(ARCHIVE):
	curl -L -o $(ARCHIVE) http://downloads.sourceforge.net/project/pmt/pngcrush/old-versions/1.8/$(VERSION)/pngcrush-$(VERSION).tar.gz

tmp/pngcrush.c: pngcrush.patch $(ARCHIVE)
	test -d tmp || mkdir -p tmp
	tar xzf $(ARCHIVE) -C tmp --strip-components=1 --exclude=Makefile

pngcrush.c: tmp/pngcrush.c
	( cd tmp; patch --forward -p1 < ../pngcrush.patch )
	-rm tmp/png.h tmp/pngconf.h 2>/dev/null
	cp tmp/*.[ch] ./
	touch pngcrush.c

clean:
	-rm -rf tmp *.c *.h $(ARCHIVE) patched

install:

.PHONY: all build clean
