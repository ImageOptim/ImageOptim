
Sparkle.framework: /tmp/sparkle.zip
	-rm -rf Sparkle.framework
	unzip -o /tmp/sparkle.zip 'With Garbage Collection/*' && mv 'With Garbage Collection/Sparkle.framework' ./
	-rm -rf /tmp/sparkle.zip 'With Garbage Collection'
	-rm -rf Sparkle.framework/Versions/A/Resources/fr_CA.lproj

/tmp/sparkle.zip:
	curl http://sparkle.andymatuschak.org/files/Sparkle%201.5b6.zip -o /tmp/sparkle.zip

clean:
	-rm -rf 'With Garbage Collection'

install:
	
