all: zopfli/src

zopfli/src: ../.gitmodules
	git submodule init zopfli
	git submodule update --depth=1 zopfli && touch zopfli/src
