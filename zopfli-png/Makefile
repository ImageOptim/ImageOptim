build: all

all: zopfli/src

zopfli/src: ../.gitmodules
	../scripts/fetch-submodule zopfli && touch zopfli/src

.PHONY: build all install clean

