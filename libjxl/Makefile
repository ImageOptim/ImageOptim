# libjxl needs several of its own third_party submodules: highway and brotli
# (core codec deps), libjpeg-turbo (lossless JPEG transcoding in cjxl), lcms
# (required whenever JPEGXL_ENABLE_SKCMS is off) and libpng + zlib (pulled in
# by JPEGXL_BUNDLE_LIBPNG for the tools' PNG I/O). testdata and the disabled
# backends are deliberately left uninitialised.
NESTED_SUBMODULES = third_party/highway third_party/brotli third_party/libjpeg-turbo \
                    third_party/lcms third_party/libpng third_party/zlib

build: all

all: submodules.stamp

submodules.stamp: ../.gitmodules
	../scripts/fetch-submodule src
	cd src && git submodule update --init $(NESTED_SUBMODULES)
	touch submodules.stamp

clean:
	-rm -rf build submodules.stamp

.PHONY: build all install clean
