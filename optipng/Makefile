
VERSION=0.6.3

src/optipng.c:
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/optipng-$(VERSION).tar.gz | tar vxz --strip-components=1 optipng-$(VERSION)/src optipng-$(VERSION)/lib/pngxtern
	patch -p0 -i remove_nonpng_formats.patch
	patch -p0 -i dirtyalpha.patch
	
clean:

install:
	