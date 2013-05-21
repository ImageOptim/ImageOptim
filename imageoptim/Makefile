SPARKLE=$(TARGET_BUILD_DIR)/Sparkle.framework

all: $(SPARKLE) pngout

$(SPARKLE): /tmp/sparkle.zip
	-rm -rf $(SPARKLE)
	unzip -o /tmp/sparkle.zip 'With Garbage Collection/*' && mv 'With Garbage Collection/Sparkle.framework' $(SPARKLE)
	-rm -rf 'With Garbage Collection'
	-rm -rf $(SPARKLE)/Versions/A/Resources/fr_CA.lproj

/tmp/sparkle.zip:
	curl http://sparkle.andymatuschak.org/files/Sparkle%201.5b6.zip -o /tmp/sparkle.zip

pngout:
	curl http://static.jonof.id.au/dl/kenutils/pngout-20130221-darwin.tar.gz | tar xz
	mv pngout-20130221-darwin/pngout pngout

clean:
	-rm -rf $(SPARKLE) pngout /tmp/sparkle.zip

install:
