# avifenc/avifdec need a libjpeg: libavif refuses to build its apps with
# AVIF_JPEG=OFF. It is built from jpegli's vendored libjpeg-turbo, so this
# delegates to libjpeg's Makefile rather than initialising that tree here.
build: all

all: submodules.stamp

submodules.stamp: ../.gitmodules
	../scripts/fetch-submodule src
	$(MAKE) -C ../libjpeg
	touch submodules.stamp

clean:
	-rm -rf build submodules.stamp

.PHONY: build all install clean
