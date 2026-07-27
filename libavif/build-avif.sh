#!/bin/bash
# Build avifenc + avifdec as universal static executables for macOS.
# Called from Xcode's "Run Script" build phase.
#
# aom, zlib/libpng and libjpeg are all built in LOCAL mode, so libavif
# fetches and builds versions it is known to work with. zlib/libpng are
# required because AVIFWorker round-trips through PNG (avifdec -> png ->
# avifenc); libjpeg is not used by that path, but libavif refuses to build
# its apps with AVIF_JPEG=OFF, so it is built too.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_ROOT="$SCRIPT_DIR/build"
OUTPUT_DIR="$BUILD_ROOT"

# Use Xcode's deployment target if available, otherwise default
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"
export MACOSX_DEPLOYMENT_TARGET

ARCHS=(arm64 x86_64)

mkdir -p "$OUTPUT_DIR"

BUILD_CACHE_HELPER="$SCRIPT_DIR/../scripts/build-cache.sh"
source "$BUILD_CACHE_HELPER"

MARKER="$OUTPUT_DIR/.build_marker"
BUILD_SIGNATURE=$(build_cache_signature \
    "$0" \
    "deployment-target=$MACOSX_DEPLOYMENT_TARGET;archs=${ARCHS[*]}" \
    "$SRC_DIR")
if build_cache_is_current "$MARKER" "$BUILD_SIGNATURE" \
    "$OUTPUT_DIR/avifenc" "$OUTPUT_DIR/avifdec"; then
    echo "avif: already built (up to date)"
    exit 0
fi

build_arch() {
    local ARCH=$1
    local BUILD_DIR="$BUILD_ROOT/$ARCH"

    echo "avif: building for $ARCH (this may take several minutes for aom)..."
    mkdir -p "$BUILD_DIR"

    # aom cross-compiles per slice, so it needs to be told the target CPU
    # explicitly; nasm is disabled because the assembly paths do not
    # cross-assemble cleanly here.
    local AOM_CPU="$ARCH"

    cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_CXX_FLAGS="-fPIC" \
        -DBUILD_SHARED_LIBS=OFF \
        -DAVIF_BUILD_APPS=ON \
        -DAVIF_BUILD_TESTS=OFF \
        -DAVIF_CODEC_AOM=LOCAL \
        -DAVIF_CODEC_DAV1D=OFF \
        -DAVIF_LIBYUV=OFF \
        -DAVIF_ZLIBPNG=LOCAL \
        -DAVIF_JPEG=LOCAL \
        -DAOM_TARGET_CPU="$AOM_CPU" \
        -DENABLE_NASM=OFF \
        -G Ninja \
        2>&1 | tail -10

    cmake --build "$BUILD_DIR" --target avifenc avifdec --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -5
}

for ARCH in "${ARCHS[@]}"; do
    build_arch "$ARCH"
done

echo "avif: creating universal binaries..."

for TOOL in avifenc avifdec; do
    INPUTS=()
    for ARCH in "${ARCHS[@]}"; do
        TOOL_PATH="$BUILD_ROOT/$ARCH/$TOOL"
        if [ ! -f "$TOOL_PATH" ]; then
            echo "ERROR: Could not find $TOOL for $ARCH at $TOOL_PATH" >&2
            find "$BUILD_ROOT/$ARCH" -name "$TOOL" -type f 2>/dev/null >&2
            exit 1
        fi
        INPUTS+=("$TOOL_PATH")
    done
    lipo -create "${INPUTS[@]}" -output "$OUTPUT_DIR/$TOOL"
    echo "  Created: $OUTPUT_DIR/$TOOL"
done

build_cache_write "$MARKER" "$BUILD_SIGNATURE"
echo "avif: build complete."
