#!/bin/bash
# Build avifenc + avifdec as universal static executables for macOS.
# Called from Xcode's "Run Script" build phase.
# Uses FetchContent to build aom codec from source (LOCAL mode).
# Builds libpng and libjpeg-turbo from libjxl's third_party sources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_ROOT="$SCRIPT_DIR/build"
OUTPUT_DIR="$BUILD_ROOT"

# Source dirs for image libraries (from libjxl's third_party)
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBPNG_SRC="$REPO_ROOT/libjpeg/src/third_party/libpng"
ZLIB_SRC="$REPO_ROOT/libjpeg/src/third_party/zlib"
LIBJPEG_SRC="$REPO_ROOT/libjpeg/src/third_party/libjpeg-turbo"

# Use Xcode's deployment target if available, otherwise default
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"
export MACOSX_DEPLOYMENT_TARGET

ARCHS=(arm64 x86_64)

mkdir -p "$OUTPUT_DIR"

# Check if we need to rebuild
MARKER="$OUTPUT_DIR/.build_marker"
if [ -f "$MARKER" ] && [ -f "$OUTPUT_DIR/avifenc" ] && [ -f "$OUTPUT_DIR/avifdec" ]; then
    MARKER_TIME=$(stat -f %m "$MARKER" 2>/dev/null || echo 0)
    CMAKE_TIME=$(stat -f %m "$SRC_DIR/CMakeLists.txt" 2>/dev/null || echo 1)
    if [ "$MARKER_TIME" -ge "$CMAKE_TIME" ]; then
        echo "avif: already built (up to date)"
        exit 0
    fi
fi

build_deps() {
    local ARCH=$1
    local DEPS_DIR="$BUILD_ROOT/deps-$ARCH"

    # Skip if deps already built
    if [ -f "$DEPS_DIR/install/lib/libpng.a" ] && [ -f "$DEPS_DIR/install/lib/libjpeg.a" ]; then
        echo "avif: dependencies already built for $ARCH"
        return
    fi

    echo "avif: building dependencies (zlib, libpng, libjpeg-turbo) for $ARCH..."

    # Build zlib
    local ZLIB_BUILD="$DEPS_DIR/zlib"
    mkdir -p "$ZLIB_BUILD"
    cmake -S "$ZLIB_SRC" -B "$ZLIB_BUILD" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_PREFIX="$DEPS_DIR/install" \
        -G Ninja 2>&1 | tail -3
    cmake --build "$ZLIB_BUILD" --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -3
    cmake --install "$ZLIB_BUILD" --config Release 2>&1 | tail -3

    # Build libpng (needs zlib)
    local PNG_BUILD="$DEPS_DIR/libpng"
    mkdir -p "$PNG_BUILD"
    cmake -S "$LIBPNG_SRC" -B "$PNG_BUILD" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DBUILD_SHARED_LIBS=OFF \
        -DPNG_SHARED=OFF \
        -DPNG_STATIC=ON \
        -DPNG_TOOLS=OFF \
        -DPNG_TESTS=OFF \
        -DCMAKE_PREFIX_PATH="$DEPS_DIR/install" \
        -DCMAKE_INSTALL_PREFIX="$DEPS_DIR/install" \
        -G Ninja 2>&1 | tail -3
    cmake --build "$PNG_BUILD" --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -3
    cmake --install "$PNG_BUILD" --config Release 2>&1 | tail -3

    # Build libjpeg-turbo
    local JPEG_BUILD="$DEPS_DIR/libjpeg"
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
}

build_arch() {
    local ARCH=$1
    local BUILD_DIR="$BUILD_ROOT/$ARCH"
    local DEPS_DIR="$BUILD_ROOT/deps-$ARCH"

    # Build dependencies first
    build_deps "$ARCH"

    echo "avif: building for $ARCH (this may take several minutes for aom)..."
    mkdir -p "$BUILD_DIR"

    # Set AOM_TARGET_CPU for cross-compilation
    local AOM_CPU
    if [ "$ARCH" = "arm64" ]; then
        AOM_CPU="arm64"
    else
        AOM_CPU="x86_64"
    fi

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
        -DAVIF_ZLIBPNG=SYSTEM \
        -DAVIF_JPEG=SYSTEM \
        -DAOM_TARGET_CPU="$AOM_CPU" \
        -DENABLE_NASM=OFF \
        -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
        -DPNG_LIBRARY="$DEPS_DIR/install/lib/libpng.a" \
        -DPNG_PNG_INCLUDE_DIR="$DEPS_DIR/install/include" \
        -DJPEG_LIBRARY="$DEPS_DIR/install/lib/libjpeg.a" \
        -DJPEG_INCLUDE_DIR="$DEPS_DIR/install/include" \
        -DZLIB_LIBRARY="$DEPS_DIR/install/lib/libz.a" \
        -DZLIB_INCLUDE_DIR="$DEPS_DIR/install/include" \
        -DCMAKE_PREFIX_PATH="$DEPS_DIR/install" \
        -G Ninja \
        2>&1 | tail -10

    cmake --build "$BUILD_DIR" --target avifenc avifdec --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -5
}

for ARCH in "${ARCHS[@]}"; do
    build_arch "$ARCH"
done

echo "avif: creating output binaries..."

for TOOL in avifenc avifdec; do
    INPUTS=()
    for ARCH in "${ARCHS[@]}"; do
        TOOL_PATH="$BUILD_ROOT/$ARCH/$TOOL"
        if [ ! -f "$TOOL_PATH" ]; then
            echo "ERROR: Could not find $TOOL for $ARCH at $TOOL_PATH"
            find "$BUILD_ROOT/$ARCH" -name "$TOOL" -type f 2>/dev/null
            exit 1
        fi
        INPUTS+=("$TOOL_PATH")
    done
    if [ ${#INPUTS[@]} -eq 1 ]; then
        cp "${INPUTS[0]}" "$OUTPUT_DIR/$TOOL"
    else
        lipo -create "${INPUTS[@]}" -output "$OUTPUT_DIR/$TOOL"
    fi
    echo "  Created: $OUTPUT_DIR/$TOOL"
done

touch "$MARKER"
echo "avif: build complete."
