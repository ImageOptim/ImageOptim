build: all

all: submodules.stamp

submodules.stamp: ../.gitmodules
	../scripts/fetch-submodule src
	touch submodules.stamp

clean:
	-rm -rf build submodules.stamp

.PHONY: build all install clean
