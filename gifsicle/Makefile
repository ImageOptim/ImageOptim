build: all

all: orig/src

orig/src: ../.gitmodules
	../scripts/fetch-submodule orig && touch orig/src

clean:
	-rm -rf gifsicle

.PHONY: build all install clean
