#!/bin/bash
# Build avifenc + avifdec as universal static executables for macOS.
# Called from Xcode's "Run Script" build phase.
#
# aom and zlib/libpng are built in LOCAL mode, so libavif fetches and builds
# versions it is known to work with. zlib/libpng are required because
# AVIFWorker round-trips through PNG (avifdec -> png -> avifenc).
#
# libjpeg is not used by that path, but libavif refuses to build its apps with
# AVIF_JPEG=OFF, so it has to be supplied. It is built here per architecture
# and passed in via AVIF_JPEG=SYSTEM rather than using AVIF_JPEG=LOCAL:
# libavif's LOCAL mode builds libjpeg through ExternalProject_Add, which
# forwards CMAKE_C_COMPILER and CMAKE_C_FLAGS but not CMAKE_OSX_ARCHITECTURES,
# so the sub-build always targets the host architecture. On an Apple Silicon
# machine that silently yields an arm64 libjpeg for both slices and the x86_64
# link then fails on undefined jpeg_* symbols.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_ROOT="$SCRIPT_DIR/build"
OUTPUT_DIR="$BUILD_ROOT"
LIBJPEG_SRC="$SCRIPT_DIR/../libjpeg/src/third_party/libjpeg-turbo"

# Use Xcode's deployment target if available, otherwise default
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"
export MACOSX_DEPLOYMENT_TARGET

ARCHS=(arm64 x86_64)

# Xcode runs this script directly from a build phase, and libavif has no
# Xcode subproject whose "download" target would fetch the sources first, so
# initialise them here. The Makefile only refreshes what the checkout moved.
make -C "$SCRIPT_DIR" >/dev/null

mkdir -p "$OUTPUT_DIR"

BUILD_CACHE_HELPER="$SCRIPT_DIR/../scripts/build-cache.sh"
source "$BUILD_CACHE_HELPER"

MARKER="$OUTPUT_DIR/.build_marker"
# libjpeg is statically linked into the tools, so its source belongs in the
# signature as much as libavif's own.
BUILD_SIGNATURE=$(build_cache_signature \
    "$0" \
    "deployment-target=$MACOSX_DEPLOYMENT_TARGET;archs=${ARCHS[*]}" \
    "$SRC_DIR" \
    "$LIBJPEG_SRC")
if build_cache_is_current "$MARKER" "$BUILD_SIGNATURE" \
    "$OUTPUT_DIR/avifenc" "$OUTPUT_DIR/avifdec"; then
    echo "avif: already built (up to date)"
    exit 0
fi

# Build libjpeg-turbo for one architecture. The source comes from jpegli's
# third_party tree, which libjpeg/Makefile already initialises.
build_libjpeg() {
    local ARCH=$1
    local DEPS_DIR="$BUILD_ROOT/deps-$ARCH"
    local JPEG_BUILD="$DEPS_DIR/libjpeg"
    local JPEG_MARKER="$DEPS_DIR/.build_marker"

    # Keyed on the build signature rather than the library's mere existence, so
    # a libjpeg source change rebuilds it instead of relinking the tools
    # against the old one, while a rerun after a later failure still skips it.
    if build_cache_is_current "$JPEG_MARKER" "$BUILD_SIGNATURE" \
        "$DEPS_DIR/install/lib/libjpeg.a"; then
        return
    fi

    echo "avif: building libjpeg-turbo for $ARCH..."
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
    build_cache_write "$JPEG_MARKER" "$BUILD_SIGNATURE"
}

build_arch() {
    local ARCH=$1
    local BUILD_DIR="$BUILD_ROOT/$ARCH"
    local DEPS_DIR="$BUILD_ROOT/deps-$ARCH"

    build_libjpeg "$ARCH"

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
        -DAVIF_JPEG=SYSTEM \
        -DCMAKE_PREFIX_PATH="$DEPS_DIR/install" \
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
