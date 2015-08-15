build: all

all: gifsicle/src

gifsicle/src: ../.gitmodules
	git submodule init gifsicle
	git submodule update --depth=1 gifsicle && touch gifsicle/src

.PHONY: build all install clean
