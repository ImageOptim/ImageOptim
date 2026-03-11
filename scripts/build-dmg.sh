#!/bin/bash
#
# One-step script to build ImageOptim and produce the final DMG file.
# Run from project root: ./scripts/build-dmg.sh
#
# Prerequisites:
#   - Xcode
#   - Rust (via rustup, not Homebrew)
#   - Network access for submodule fetch and build-time downloads
#
# Output: build/Release/ImageOptim-<version>.dmg

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_APP="$BUILD_DIR/Build/Products/Release/ImageOptim.app"

cd "$PROJECT_DIR"

echo "=== Step 1: Initialize submodules ==="
git submodule update --init --recursive

echo ""
echo "=== Step 2: Build ImageOptim (Release) ==="
xcodebuild -project "$PROJECT_DIR/imageoptim/ImageOptim.xcodeproj" \
    -scheme ImageOptim \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

if [ ! -d "$RELEASE_APP" ]; then
    echo "Error: Build succeeded but ImageOptim.app not found at $RELEASE_APP"
    exit 1
fi

echo ""
echo "=== Step 3: Create DMG ==="
RELEASE_DIR="$BUILD_DIR/Build/Products/Release"
VERSION=$(plutil -extract CFBundleShortVersionString raw "$RELEASE_APP/Contents/Info.plist" 2>/dev/null) || VERSION="1.9.5"
DMG_NAME="ImageOptim-${VERSION}.dmg"

# Create DMG directly (package.sh tar may fail when code signing is disabled)
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
hdiutil create -volname "ImageOptim $VERSION" \
    -srcfolder "$RELEASE_APP" \
    -ov -format UDZO \
    "$DMG_PATH"
echo "Created: $DMG_PATH"

if [ -f "$DMG_PATH" ]; then
    echo ""
    echo "=== Done ==="
    echo "DMG: $DMG_PATH"
    echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
else
    echo "Error: DMG was not created"
    exit 1
fi
