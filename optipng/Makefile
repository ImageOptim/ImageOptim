
VERSION=0.6.4

all: patched

patched: src/optipng.c
	patch -p1 -i remove_nonpng_formats.patch
	patch -p1 -i dirtyalpha.patch
	touch patched	

src/optipng.c:
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/optipng-$(VERSION).tar.gz | tar vxz --strip-components=1 optipng-$(VERSION)/src optipng-$(VERSION)/lib/pngxtern
	
clean:
	test \! -e ./patched || rm ./patched
	test \! -d ./src/ || rm -rf ./src/
	test \! -d ./lib/ || rm -rf ./lib/

install:
	