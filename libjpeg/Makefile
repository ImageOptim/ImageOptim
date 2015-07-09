all: src/jpeglib.h

src/jpeglib.h: ../.gitmodules
	git submodule init src
	git submodule update --depth=1 src && touch src/jpeglib.h
