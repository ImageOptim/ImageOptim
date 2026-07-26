VERSION=1.6.58

build: all

all: png.h

png.h:
	curl -sL https://github.com/pnggroup/libpng/archive/refs/tags/v$(VERSION).tar.gz | \
	  tar xz --strip-components=1 --exclude='Makefile*' \
	    'libpng-$(VERSION)/*.c' 'libpng-$(VERSION)/*.h' \
	    'libpng-$(VERSION)/arm/*' \
	    'libpng-$(VERSION)/scripts/pnglibconf.h.prebuilt'
	# libpng >= 1.5 is configured through pnglibconf.h, not through defines
	# in config.h. Use the stock configuration...
	cp scripts/pnglibconf.h.prebuilt pnglibconf.h
	# ...except that pngcrush calls png_set_option(PNG_IGNORE_ADLER32), which
	# libpng only declares when built with this option available.
	sed -i.bak 's|/\*#undef PNG_DISABLE_ADLER32_CHECK_SUPPORTED\*/|#define PNG_DISABLE_ADLER32_CHECK_SUPPORTED|' pnglibconf.h
	rm -f pnglibconf.h.bak
	grep -q '^#define PNG_DISABLE_ADLER32_CHECK_SUPPORTED' pnglibconf.h
	# These carry a main() and are not part of the library.
	rm -f example.c pngtest.c

clean:
	# config.h is ours and tracked; everything else here is extracted.
	-rm -rf *.c scripts arm intel loongarch mips powerpc riscv
	-find . -maxdepth 1 -name '*.h' ! -name config.h -delete

install:

.PHONY: build all install clean
