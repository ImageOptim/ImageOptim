build: all

all: src/pngquant.c

src/pngquant.c: ../.gitmodules
	../scripts/fetch-submodule src && touch src/pngquant.c

.PHONY: build all install clean
