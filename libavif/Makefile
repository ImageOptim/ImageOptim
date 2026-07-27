# avifenc/avifdec need a libjpeg: libavif refuses to build its apps with
# AVIF_JPEG=OFF. It is built from jpegli's vendored libjpeg-turbo, so this
# delegates to libjpeg's Makefile rather than initialising that tree here.
build: all

# The pinned libavif revision is a gitlink, which a checkout can move without
# changing .gitmodules, so a file stamp would leave the previous source in
# place. Updating the submodule is cheap once it is current, so it runs on
# every invocation instead.
all:
	../scripts/fetch-submodule src
	$(MAKE) -C ../libjpeg

clean:
	-rm -rf build

.PHONY: build all install clean
