#!/bin/bash
SPARKLE=$1

TARGET_TEMP_DIR=${TARGET_TEMP_DIR:-/tmp/}
SPARKLETMP=$TARGET_TEMP_DIR/Sparkle.framework
SPARKLEFALLBACK=${SRCROOT:-/tmp/none/}/Sparkle.framework
SPARKLEZIP=$TARGET_TEMP_DIR/sparkle.tar.bz2

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
curl -L https://github.com/sparkle-project/Sparkle/releases/download/1.9.0/Sparkle-1.9.0.tar.bz2 -o "$SPARKLEZIP" || exit 1
tar xjvf "$SPARKLEZIP" --strip-components 1 --include '*/Sparkle.framework' -C "$TARGET_TEMP_DIR/" || exit 1

cp -R "$SPARKLETMP" "$SPARKLE"
