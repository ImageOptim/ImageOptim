#!/bin/bash
#
# Build, tag, and publish ImageOptim release to GitHub.
# Creates local release build, git tag, pushes to GitHub, and uploads DMG + tar.bz2.
#
# Prerequisites:
#   - gh (GitHub CLI) installed and authenticated
#   - Xcode, Rust (rustup)
#   - Clean git status (commit changes first)
#
# Usage:
#   ./scripts/release-github.sh [VERSION]
#   ./scripts/release-github.sh 1.9.5
#   RELEASE_YES=1 ./scripts/release-github.sh   # skip uncommitted-changes prompt
#
# If VERSION is omitted, reads from release.xcconfig.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$BUILD_DIR/Build/Products/Release"

cd "$PROJECT_DIR"

# Get version
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(grep 'CURRENT_PROJECT_VERSION=' imageoptim/release.xcconfig | cut -d= -f2 | tr -d ';')
fi
if [ -z "$VERSION" ]; then
    echo "Error: Could not determine version. Pass as argument or set in release.xcconfig"
    exit 1
fi

TAG="v${VERSION}"
DMG_NAME="ImageOptim-${VERSION}.dmg"
BZ2_NAME="ImageOptim${VERSION}.tar.bz2"

echo "=== ImageOptim Release $VERSION ==="
echo ""

# Ensure submodules are initialized
git submodule update --init --recursive

# Check git status
if [ -n "$(git status --porcelain)" ] && [ -z "$RELEASE_YES" ]; then
    echo "Warning: Uncommitted changes detected. Commit before releasing."
    git status --short
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Build
echo "=== Step 1: Build ==="
./scripts/build-dmg.sh

# Step 2: Create tar.bz2 (Sparkle)
echo ""
echo "=== Step 2: Create tar.bz2 ==="
./scripts/package.sh "$RELEASE_DIR" "$VERSION"
BZ2_PATH="$RELEASE_DIR/$BZ2_NAME"

# Step 3: Create local release copy
RELEASE_OUTPUT="$PROJECT_DIR/release-$VERSION"
mkdir -p "$RELEASE_OUTPUT"
cp "$RELEASE_DIR/$DMG_NAME" "$RELEASE_OUTPUT/"
cp "$BZ2_PATH" "$RELEASE_OUTPUT/"
echo ""
echo "Local release saved to: $RELEASE_OUTPUT"

# Step 4: Git tag
echo ""
echo "=== Step 3: Create tag $TAG ==="
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag $TAG already exists. Delete with: git tag -d $TAG"
    exit 1
fi
git tag -a "$TAG" -m "Release $VERSION: Apple Silicon support, universal binary"

# Step 5: Push to GitHub (including submodule refs)
echo ""
echo "=== Step 4: Push to GitHub ==="
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$BRANCH" --recurse-submodules=on-demand
git push origin "$TAG"

# Step 6: Create GitHub Release
echo ""
echo "=== Step 5: Create GitHub Release ==="
RELEASE_NOTES="## ImageOptim $VERSION

### Apple Silicon (arm64) Support
- Universal binary for Apple Silicon and Intel Macs
- Native performance on M1/M2/M3 chips

### Build System
- One-step build: \`./scripts/build-dmg.sh\`
- advpng: libzopfli and libdeflate linking fixes"

RELEASE_FILES=("$RELEASE_OUTPUT/$DMG_NAME" "$RELEASE_OUTPUT/$BZ2_NAME")
gh release create "$TAG" "${RELEASE_FILES[@]}" \
    --title "ImageOptim $VERSION" \
    --notes "$RELEASE_NOTES"

echo ""
echo "=== Done ==="
echo "Release: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/releases/tag/$TAG"
