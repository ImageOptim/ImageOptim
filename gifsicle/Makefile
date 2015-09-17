build: all

all: gifsicle/src

gifsicle/src: ../.gitmodules
	../scripts/fetch-submodule gifsicle && touch gifsicle/src

.PHONY: build all install clean
