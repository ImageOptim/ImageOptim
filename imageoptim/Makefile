HELPINDEXES=$(addsuffix Help.helpindex, $(wildcard *.lproj/Help/))
SUBMODULES=../Sparkle/Sparkle ../gifsicle/src

all: $(SUBMODULES) pngout helpindexes

$(SUBMODULES):
	git submodule init
	git submodule update --depth=1

pngout:
	curl http://static.jonof.id.au/dl/kenutils/pngout-20150319-darwin.tar.gz | tar xz
	mv pngout-20150319-darwin/pngout pngout

clean:
	-rm -rf pngout

install:

helpindexes:: $(HELPINDEXES)

%/Help.helpindex: %/index.html %/prefs.html
	./makehelp.sh $(patsubst %.lproj/Help/Help.helpindex,%,$@)
