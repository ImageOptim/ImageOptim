#!/bin/sh
#

if [ -d .git ]; then
    # Get version from git tags, removing the 'v' prefix
    VERSION=`git describe --match 'v*' 2>/dev/null | sed 's/^v//'`
fi

if [ -f .version ]; then
    # Get version from the .version file
    VERSION=`cat .version`
fi

if [ -z $VERSION ]; then
    VERSION="none"
fi

printf '%s' "$VERSION"

