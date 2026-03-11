VERSION=1.8.10
ARCHIVE=/tmp/pngcrush-$(VERSION).tar.gz

build: all

all: pngcrush.c

pngcrush.c:
	@echo "Using pre-installed pngcrush source"

clean:
	-rm -rf tmp *.c *.h $(ARCHIVE) patched

install:

.PHONY: all build clean
