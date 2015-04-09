HELPINDEXES=$(addsuffix Help.helpindex, $(wildcard *.lproj/Help/))

all: ../Sparkle pngout helpindexes

../Sparkle:
	git clone --depth=1 https://github.com/sparkle-project/Sparkle.git $@

pngout:
	curl http://static.jonof.id.au/dl/kenutils/pngout-20150319-darwin.tar.gz | tar xz
	mv pngout-20150319-darwin/pngout pngout

clean:
	-rm -rf pngout

install:

helpindexes:: $(HELPINDEXES)

%/Help.helpindex: %/index.html %/prefs.html
	./makehelp.sh $(patsubst %.lproj/Help/Help.helpindex,%,$@)
