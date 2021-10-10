HELPINDEXES=$(addsuffix Help.helpindex, $(wildcard *.lproj/Help/))
SUBMODULES=../Sparkle/Sparkle ../svgcleaner/src

build: all

all: $(SUBMODULES) pngout helpindexes

$(SUBMODULES): ../.gitmodules
	../scripts/fetch-submodule $(shell dirname $@) && touch $@

pngout:
	curl -L https://www.jonof.id.au/files/kenutils/pngout-20150920-darwin.tar.gz | tar xz
	mv pngout-20150920-darwin/pngout pngout

clean:
	-rm -rf pngout

install:

helpindexes:: $(HELPINDEXES)

%/Help.helpindex: %/index.html %/prefs.html
	./makehelp.sh $(patsubst %.lproj/Help/Help.helpindex,%,$@)

.PHONY: build all install clean
