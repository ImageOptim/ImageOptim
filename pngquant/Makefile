build: all

all: src/pngquant.c

src/pngquant.c: ../.gitmodules
	git submodule init src
	git submodule update --depth=100 src && touch src/pngquant.c

.PHONY: build all install clean
