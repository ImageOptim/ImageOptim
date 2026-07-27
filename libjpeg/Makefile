# jpegli needs three of its own third_party submodules: highway (the hwy
# target), libjpeg-turbo (the libjpeg headers jpegli configures) and lcms
# (required whenever JPEGLI_ENABLE_SKCMS is off, as it is here). testdata and
# the disabled codec backends are deliberately left uninitialised — they are
# large and nothing in this build reads them.
NESTED_SUBMODULES = third_party/highway third_party/libjpeg-turbo third_party/lcms

build: all

all: submodules.stamp

submodules.stamp: ../.gitmodules
	../scripts/fetch-submodule src
	cd src && git submodule update --init $(NESTED_SUBMODULES)
	touch submodules.stamp

clean:
	-rm -rf build submodules.stamp

.PHONY: build all install clean
