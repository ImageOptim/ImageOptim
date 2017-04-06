
VERSION=0.6.5
OPTIPNG_FILENAME=optipng-$(VERSION).tar.gz

build: all

all: patched

patched: src/optipng.c
	patch -p1 -i remove_nonpng_formats.patch || exit 1
	patch -p1 -i dirtyalpha.patch || exit 1
	touch patched

src/optipng.c: /tmp/$(OPTIPNG_FILENAME)
	-rm -f patched
	tar xzf /tmp/$(OPTIPNG_FILENAME) --strip-components=1 optipng-$(VERSION)/src optipng-$(VERSION)/lib/pngxtern

/tmp/$(OPTIPNG_FILENAME):
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/$(OPTIPNG_FILENAME) -o /tmp/$(OPTIPNG_FILENAME)

clean:
	- rm -rf ./patched ./src/ ./lib/ /tmp/$(OPTIPNG_FILENAME)

install: all

.PHONY: build all install clean
