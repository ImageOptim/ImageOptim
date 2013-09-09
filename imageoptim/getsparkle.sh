#!/bin/bash
SPAKRLE=$1

TARGET_TEMP_DIR=${TARGET_TEMP_DIR:-/tmp/}
SPARKLETMP=$TARGET_TEMP_DIR/Sparkle.framework
SPARKLEFALLBACK=${SRCROOT:-/tmp/none/}/Sparkle.framework
SPARKLEZIP=$TARGET_TEMP_DIR/sparkle.zip

if test -e "$SPAKRLE"; then
    exit 0;
fi

if test -e "$SPAKRLETMP"; then
    cp -R "$SPAKRLETMP" "$SPAKRLE" && exit 0
fi

if test -e "$SPARKLEFALLBACK"; then
    cp -R "$SPARKLEFALLBACK" "$SPAKRLE" && exit 0
fi

echo Downloading Sparkle

test ! -e "$SPAKRLEZIP" || rm -rf "$SPAKRLEZIP"
curl http://sparkle.andymatuschak.org/files/Sparkle%201.5b6.zip -o "$SPAKRLEZIP"
unzip -o "$SPAKRLEZIP" 'With Garbage Collection/*' -d "$TARGET_TEMP_DIR"
mv "$TARGET_TEMP_DIR/With Garbage Collection/Sparkle.framework" "$SPAKRLETMP"
rm -rf "$TARGET_TEMP_DIR/With Garbage Collection"
rm -rf "$SPAKRLETMP/Versions/A/Resources/fr_CA.lproj"

cp -R "$SPAKRLETMP" "$SPAKRLE"
