VERSION=2.6

build: all

all: repng.cc

repng.cc:
	curl -sL https://github.com/amadvance/advancecomp/releases/download/v$(VERSION)/advancecomp-$(VERSION).tar.gz | \
	  tar xz --strip-components=1 --exclude='Makefile'

clean:
	# config.h is ours and tracked; everything else here is extracted.
	-rm -rf *.c *.cc 7z lib libdeflate zopfli doc test \
	  aclocal.m4 autogen.sh autover.sh compile config.guess config.sub \
	  configure configure.ac install-sh missing Makefile.am Makefile.in \
	  AUTHORS COPYING HISTORY INSTALL README
	-find . -maxdepth 1 -name '*.h' ! -name config.h -delete

install:

.PHONY: build all install clean
