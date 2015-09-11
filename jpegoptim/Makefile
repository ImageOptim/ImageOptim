build: all

all:  src/jpegoptim.h

src/jpegoptim.h: ../.gitmodules
	git submodule init src
	git submodule update src && touch src/jpegoptim.h

.PHONY: build all install clean
