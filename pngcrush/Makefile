.PHONY: all

all: pngcrush.c

pngcrush.c:
	curl -L http://downloads.sourceforge.net/project/pmt/pngcrush/1.7.43/pngcrush-1.7.43.tar.gz | tar xz --strip-components=1 --exclude=Makefile
	-rm png.h pngconf.h 2>/dev/null

clean:
	-rm *.c *.h 2>/dev/null

install:
