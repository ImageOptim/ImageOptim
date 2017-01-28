build: all

all: patched

patched: gifsicle/src
	patch --forward -p1 -d gifsicle < gifsicle-1.89-imageoptim.patch && touch patched

gifsicle/src: ../.gitmodules
	../scripts/fetch-submodule gifsicle && touch gifsicle/src

clean:
	-rm patched

.PHONY: build all install clean
