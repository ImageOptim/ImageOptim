build: all

all: src/jpeglib.h

src/jpeglib.h: ../.gitmodules
	../scripts/fetch-submodule src && touch src/jpeglib.h

.PHONY: build all install clean
