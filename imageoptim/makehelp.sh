#!/bin/bash
shopt -s nullglob
LANG=$1

SRC=$LANG.lproj/Help/
DST=$LANG.lproj/Help/Help.helpindex

TMP=/tmp/helpindex-$LANG

echo "Making $LANG to $DST"

test -d "$TMP" || mkdir "$TMP"

for i in ${SRC}*.html; do
    tidy --tidy-mark no --show-errors 0 -q -utf8 -asxhtml < "$i" > "$TMP/`basename "$i"`";
done;

hiutil -C -ag -m 1 -r "http://imageoptim.com/$LANG/" -v -s "$LANG" -f "$DST" "$TMP"
