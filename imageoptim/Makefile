HELPINDEXES=$(addsuffix Help.helpindex, $(wildcard *.lproj/Help/))
SUBMODULES=../Sparkle/Sparkle ../svgcleaner/src

build: all

all: $(SUBMODULES) pngout helpindexes

$(SUBMODULES): ../.gitmodules
	../scripts/fetch-submodule $(shell dirname $@) && touch $@

pngout:
	curl -LO https://www.jonof.id.au/files/kenutils/pngout-20230322-mac.zip
	unzip -p pngout-20230322-mac.zip pngout-20230322-mac/pngout > pngout
	chmod a+rx pngout
	codesign -s "Developer ID" ./pngout --force

clean:
	-rm -rf pngout pngout-20230322-mac.zip

install:

helpindexes:: $(HELPINDEXES)

%/Help.helpindex: %/index.html %/prefs.html
	./makehelp.sh $(patsubst %.lproj/Help/Help.helpindex,%,$@)

# Packaging targets - run after building in Xcode.
# Usage: make archive TARGET_BUILD_DIR=/path/to/Build/Products/Release
#        make dmg TARGET_BUILD_DIR=/path/to/Build/Products/Release
archive:
	@if [ -z "$(TARGET_BUILD_DIR)" ]; then \
		echo "Usage: make archive TARGET_BUILD_DIR=/path/to/Build/Products/Release"; \
		echo "Or run: ../scripts/package.sh /path/to/build/Release"; \
		exit 1; \
	fi
	../scripts/package.sh "$(TARGET_BUILD_DIR)" "$(MARKETING_VERSION)"

dmg:
	@if [ -z "$(TARGET_BUILD_DIR)" ]; then \
		echo "Usage: make dmg TARGET_BUILD_DIR=/path/to/Build/Products/Release"; \
		echo "Or run: ../scripts/package.sh /path/to/build/Release VERSION dmg"; \
		exit 1; \
	fi
	../scripts/package.sh "$(TARGET_BUILD_DIR)" "$(MARKETING_VERSION)" dmg

.PHONY: build all install clean archive dmg
