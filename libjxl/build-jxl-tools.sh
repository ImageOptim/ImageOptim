#!/bin/bash
# Build cjxl, djxl and jxlinfo as universal static executables for macOS.
# Called from Xcode's "Run Script" build phase.
#
# libjxl is a separate submodule from the JPEG codec: jpegli used to live in
# this repository but was removed in March 2026, so libjpeg/src tracks
# google/jpegli and this tracks libjxl purely for the JPEG XL tools.
#
# libjpeg-turbo is built from libjxl's own third_party tree so cjxl can
# losslessly transcode JPEG into JPEG XL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_ROOT="$SCRIPT_DIR/build"
OUTPUT_DIR="$BUILD_ROOT"
LIBJPEG_SRC="$SRC_DIR/third_party/libjpeg-turbo"

# Use Xcode's deployment target if available, otherwise default
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"
export MACOSX_DEPLOYMENT_TARGET

ARCHS=(arm64 x86_64)

# Xcode runs this script directly from a build phase, and libjxl has no Xcode
# subproject whose "download" target would fetch the sources first, so
# initialise them here. This has to happen before the cache signature below is
# computed, because that signature covers the checked-out libjxl revision.
make -C "$SCRIPT_DIR" >/dev/null

mkdir -p "$OUTPUT_DIR"

BUILD_CACHE_HELPER="$SCRIPT_DIR/../scripts/build-cache.sh"
source "$BUILD_CACHE_HELPER"

MARKER="$OUTPUT_DIR/.build_marker"
BUILD_SIGNATURE=$(build_cache_signature \
    "$0" \
    "deployment-target=$MACOSX_DEPLOYMENT_TARGET;archs=${ARCHS[*]}" \
    "$SRC_DIR")
if build_cache_is_current "$MARKER" "$BUILD_SIGNATURE" \
    "$OUTPUT_DIR/cjxl" "$OUTPUT_DIR/djxl" "$OUTPUT_DIR/jxlinfo"; then
    echo "jxl-tools: already built (up to date)"
    exit 0
fi

build_libjpeg() {
    local ARCH=$1
    local DEPS_DIR="$BUILD_ROOT/deps-$ARCH"
    local JPEG_BUILD="$DEPS_DIR/libjpeg"

    # Keyed by the same signature as the tools, so a changed deployment target,
    # toolchain or libjxl revision rebuilds this dependency too.
    if build_cache_is_current "$DEPS_DIR/.build_marker" "$BUILD_SIGNATURE" \
        "$DEPS_DIR/install/lib/libjpeg.a"; then
        return
    fi

    echo "jxl-tools: building libjpeg-turbo for $ARCH..."
    rm -rf "$DEPS_DIR"
    mkdir -p "$JPEG_BUILD"
    cmake -S "$LIBJPEG_SRC" -B "$JPEG_BUILD" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_SHARED=OFF \
        -DENABLE_STATIC=ON \
        -DWITH_TURBOJPEG=OFF \
        -DCMAKE_INSTALL_PREFIX="$DEPS_DIR/install" \
        -G Ninja 2>&1 | tail -3
    cmake --build "$JPEG_BUILD" --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -3
    cmake --install "$JPEG_BUILD" --config Release 2>&1 | tail -3
    build_cache_write "$DEPS_DIR/.build_marker" "$BUILD_SIGNATURE"
}

build_arch() {
    local ARCH=$1
    local BUILD_DIR="$BUILD_ROOT/$ARCH"
    local DEPS_DIR="$BUILD_ROOT/deps-$ARCH"

    build_libjpeg "$ARCH"

    echo "jxl-tools: building for $ARCH..."
    mkdir -p "$BUILD_DIR"

    cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_CXX_FLAGS="-fPIC" \
        -DJPEGXL_ENABLE_TOOLS=ON \
        -DJPEGXL_STATIC=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DJPEGXL_BUNDLE_LIBPNG=ON \
        -DJPEGXL_ENABLE_OPENEXR=OFF \
        -DJPEGXL_ENABLE_SKCMS=OFF \
        -DJPEGXL_ENABLE_SJPEG=OFF \
        -DJPEGXL_ENABLE_BENCHMARK=OFF \
        -DJPEGXL_ENABLE_EXAMPLES=OFF \
        -DJPEGXL_ENABLE_MANPAGES=OFF \
        -DJPEGXL_ENABLE_DOXYGEN=OFF \
        -DBUILD_TESTING=OFF \
        -DCMAKE_DISABLE_FIND_PACKAGE_GIF=ON \
        -DCMAKE_PREFIX_PATH="$DEPS_DIR/install" \
        -G Ninja \
        2>&1 | tail -5

    cmake --build "$BUILD_DIR" --target cjxl djxl jxlinfo --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -5
}

for ARCH in "${ARCHS[@]}"; do
    build_arch "$ARCH"
done

echo "jxl-tools: creating universal binaries..."

for TOOL in cjxl djxl jxlinfo; do
    INPUTS=()
    for ARCH in "${ARCHS[@]}"; do
        TOOL_PATH="$BUILD_ROOT/$ARCH/tools/$TOOL"
        if [ ! -f "$TOOL_PATH" ]; then
            echo "ERROR: Could not find $TOOL for $ARCH at $TOOL_PATH" >&2
            exit 1
        fi
        INPUTS+=("$TOOL_PATH")
    done
    lipo -create "${INPUTS[@]}" -output "$OUTPUT_DIR/$TOOL"
    echo "  Created: $OUTPUT_DIR/$TOOL"
done

build_cache_write "$MARKER" "$BUILD_SIGNATURE"
echo "jxl-tools: build complete."
