#!/bin/bash
# Package ImageOptim for distribution: creates tar.bz2 (Sparkle) and optionally DMG.
# Run after building in Xcode. Requires ImageOptim.app to exist in BUILD_DIR.
#
# Usage:
#   ./scripts/package.sh [BUILD_DIR] [VERSION]
#
# Examples:
#   ./scripts/package.sh                                    # uses default paths
#   ./scripts/package.sh build/Release                      # specify build dir
#   ./scripts/package.sh build/Release 1.9.5                 # with version
#   ./scripts/package.sh build/Release 1.9.5 dmg            # also create DMG

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGEOPTIM_DIR="$PROJECT_DIR/imageoptim"

# Default: build/Release (or set OUTPUT_DIR for custom output location)
# Xcode default: ~/Library/Developer/Xcode/DerivedData/<Project>/Build/Products/Release
DEFAULT_BUILD_DIR="$PROJECT_DIR/build/Release"
BUILD_DIR="${1:-$DEFAULT_BUILD_DIR}"
# Resolve to absolute path (critical when cd'ing into BUILD_DIR for tar)
BUILD_DIR="$(cd "$PROJECT_DIR" && cd "$BUILD_DIR" && pwd)"
VERSION="${2:-}"
CREATE_DMG="${3:-}"

# Resolve version from Info.plist if not provided
if [ -z "$VERSION" ] && [ -f "$BUILD_DIR/ImageOptim.app/Contents/Info.plist" ]; then
    VERSION=$(plutil -extract CFBundleShortVersionString raw "$BUILD_DIR/ImageOptim.app/Contents/Info.plist" 2>/dev/null) || true
fi
if [ -z "$VERSION" ]; then
    VERSION="1.9.5"  # fallback
fi

APP_PATH="$BUILD_DIR/ImageOptim.app"
OPTIMAL_FILE_LIST="$IMAGEOPTIM_DIR/optimal_file_list"
OUTPUT_DIR="${OUTPUT_DIR:-$BUILD_DIR}"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: ImageOptim.app not found at $APP_PATH"
    echo "Build the project in Xcode first (Product > Build, or Cmd+B)"
    exit 1
fi

if [ ! -f "$OPTIMAL_FILE_LIST" ]; then
    echo "Error: optimal_file_list not found at $OPTIMAL_FILE_LIST"
    exit 1
fi

cd "$BUILD_DIR"

# Create tar.bz2 for Sparkle updates
ARCHIVE_NAME="ImageOptim${VERSION}.tar.bz2"
echo "Creating $ARCHIVE_NAME..."
if tar -cjf "$OUTPUT_DIR/$ARCHIVE_NAME" --files-from="$OPTIMAL_FILE_LIST" 2>/dev/null; then
    echo "Created: $OUTPUT_DIR/$ARCHIVE_NAME (optimal file list)"
else
    echo "Note: optimal file list failed (e.g. unsigned build), packaging full app..."
    tar -cjf "$OUTPUT_DIR/$ARCHIVE_NAME" ImageOptim.app
    echo "Created: $OUTPUT_DIR/$ARCHIVE_NAME (full app bundle)"
fi

# Create DMG if requested (also creates tar.bz2)
if [ "$CREATE_DMG" = "dmg" ]; then
    DMG_NAME="ImageOptim-${VERSION}.dmg"
    echo "Creating $DMG_NAME..."
    hdiutil create -volname "ImageOptim $VERSION" \
        -srcfolder "$APP_PATH" \
        -ov -format UDZO \
        "$OUTPUT_DIR/$DMG_NAME"
    echo "Created: $OUTPUT_DIR/$DMG_NAME"
fi

echo ""
echo "Next steps for Sparkle distribution:"
echo "  1. Sign the archive: ruby imageoptim/sign_update.rb $ARCHIVE_NAME dsa_priv.pem"
echo "  2. Update appcast.xml with the new enclosure and signatures"
