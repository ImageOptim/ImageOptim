#!/bin/bash
SPARKLE=$1

TARGET_TEMP_DIR=${TARGET_TEMP_DIR:-/tmp/}
SPARKLETMP=$TARGET_TEMP_DIR/Sparkle.framework
SPARKLEFALLBACK=${SRCROOT:-/tmp/none/}/Sparkle.framework
SPARKLEZIP=$TARGET_TEMP_DIR/sparkle.zip

if test -e "$SPARKLE"; then
    exit 0;
fi

if test ! -d "$(dirname "$SPARKLE")"; then
	mkdir -p "$(dirname "$SPARKLE")" || exit 1
fi

if test -e "$SPARKLETMP"; then
    cp -R "$SPARKLETMP" "$SPARKLE" && exit 0
fi

if test -e "$SPARKLEFALLBACK"; then
    cp -R "$SPARKLEFALLBACK" "$SPARKLE" && exit 0
fi

echo Downloading Sparkle

test ! -e "$SPARKLEZIP" || rm -rf "$SPARKLEZIP"
echo curl http://sparkle.andymatuschak.org/files/Sparkle%201.5b6.zip -o "$SPARKLEZIP"
curl http://sparkle.andymatuschak.org/files/Sparkle%201.5b6.zip -o "$SPARKLEZIP"
unzip -o "$SPARKLEZIP" 'With Garbage Collection/*' -d "$TARGET_TEMP_DIR"
echo mv "$TARGET_TEMP_DIR/With Garbage Collection/Sparkle.framework" "$SPARKLETMP"
mv "$TARGET_TEMP_DIR/With Garbage Collection/Sparkle.framework" "$SPARKLETMP"
rm -rf "$TARGET_TEMP_DIR/With Garbage Collection"
rm -rf "$SPARKLETMP/Versions/A/Resources/fr_CA.lproj"

cp -R "$SPARKLETMP" "$SPARKLE"
