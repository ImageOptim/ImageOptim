build: all

all: patched

patched: orig/src
	cp -R orig gifsicle
	patch --forward -p1 -d gifsicle < gifsicle-1.89-imageoptim.patch && touch patched

orig/src: ../.gitmodules
	../scripts/fetch-submodule orig && touch orig/src

clean:
	-rm -rf patched gifsicle

.PHONY: build all install clean
