all:  src/jpegoptim.h

src/jpegoptim.h: ../.gitmodules
	git submodule init src
	git submodule update --depth=1 src && touch src/jpegoptim.h
