#!/bin/bash
SPARKLE=${1:-Sparkle.framework}

TARGET_TEMP_DIR=${TARGET_TEMP_DIR:-/tmp/}
SPARKLETMP=$TARGET_TEMP_DIR/Sparkle.framework
SPARKLEFALLBACK=${SRCROOT:-/tmp/none/}/Sparkle.framework
SPARKLEZIP=$TARGET_TEMP_DIR/Sparkle-tmp.tar.bz2

if test -e "$SPARKLE"; then
    echo "$SPARKLE already exists"
    exit 0;
fi

if test ! -d "$(dirname "$SPARKLE")"; then
	mkdir -p "$(dirname "$SPARKLE")" || exit 1
fi

if test -e "$SPARKLETMP"; then
    echo "Copying Sparkle from $SPARKLETMP"
    cp -R "$SPARKLETMP" "$SPARKLE" && exit 0
fi

if test -e "$SPARKLEFALLBACK"; then
    echo "Copying Sparkle from $SPARKLEFALLBACK"
    cp -R "$SPARKLEFALLBACK" "$SPARKLE" && exit 0
fi

if test '!' -f "$SPARKLEZIP"; then
    echo "Downloading Sparkle"
    curl -L -o "$SPARKLEZIP" https://github.com/sparkle-project/Sparkle/releases/download/1.9.0/Sparkle-1.9.0.tar.bz2 || { rm -rf "$SPARKLEZIP"; exit 1; }
fi

rm -rf "$TARGET_TEMP_DIR/Sparkle.framework" "$SPARKLE"
tar xjvf "$SPARKLEZIP" --include './Sparkle.framework' -C "$TARGET_TEMP_DIR/" || exit 1

cp -R "$SPARKLETMP" "$SPARKLE"
