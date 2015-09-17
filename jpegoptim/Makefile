build: all

all:  src/jpegoptim.h

src/jpegoptim.h: ../.gitmodules
	../scripts/fetch-submodule src && touch src/jpegoptim.h

.PHONY: build all install clean
