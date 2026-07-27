# jpegli needs three of its own third_party submodules: highway (the hwy
# target), libjpeg-turbo (the libjpeg headers jpegli configures) and lcms
# (required whenever JPEGLI_ENABLE_SKCMS is off, as it is here). testdata and
# the disabled codec backends are deliberately left uninitialised — they are
# large and nothing in this build reads them.
NESTED_SUBMODULES = third_party/highway third_party/libjpeg-turbo third_party/lcms

build: all

all: submodules

# Not gated on a stamp file: bumping src's pinned commit in the superproject
# leaves ../.gitmodules (and any stamp) untouched, so a gated recipe would skip
# the update and build against the old checkout. Re-running is a no-op when the
# submodules are already at the pinned commits.
submodules:
	../scripts/fetch-submodule src
	cd src && git submodule update --init $(NESTED_SUBMODULES)

clean:
	-rm -rf build

.PHONY: build all install clean submodules
