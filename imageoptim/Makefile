SPARKLE=$(TARGET_BUILD_DIR)/Sparkle.framework
HELPINDEXES=$(addsuffix Help.helpindex, $(wildcard *.lproj/Help/))

all: $(SPARKLE) pngout helpindexes

$(SPARKLE):
	./getsparkle.sh $(SPARKLE)

pngout:
	curl http://static.jonof.id.au/dl/kenutils/pngout-20150319-darwin.tar.gz | tar xz
	mv pngout-20150319-darwin/pngout pngout

clean:
	-rm -rf $(SPARKLE) pngout /tmp/sparkle.zip /tmp/sparkle.tar.bz2

install:

helpindexes:: $(HELPINDEXES)

%/Help.helpindex: %/index.html %/prefs.html
	./makehelp.sh $(patsubst %.lproj/Help/Help.helpindex,%,$@)
