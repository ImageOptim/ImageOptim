build: all

all: guetzli/src

guetzli/src: ../.gitmodules
	../scripts/fetch-submodule guetzli && touch guetzli/src

.PHONY: build all install clean

