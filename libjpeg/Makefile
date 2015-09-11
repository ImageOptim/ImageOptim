build: all

all: src/jpeglib.h

src/jpeglib.h: ../.gitmodules
	git submodule init src
	git submodule update src && touch src/jpeglib.h

.PHONY: build all install clean
