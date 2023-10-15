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

.PHONY: build all install clean
