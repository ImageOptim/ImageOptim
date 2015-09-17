build: all

all: gifsicle/src

gifsicle/src: ../.gitmodules
	../scripts/fetch-submodule gifsicle && touch gifsicle/src
	patch -p1 -d gifsicle < gifsicle-1.89-imageoptim.patch

.PHONY: build all install clean
