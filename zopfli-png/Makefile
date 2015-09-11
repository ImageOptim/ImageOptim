build: all

all: zopfli/src

zopfli/src: ../.gitmodules
	git submodule init zopfli
	git submodule update zopfli && touch zopfli/src

.PHONY: build all install clean

