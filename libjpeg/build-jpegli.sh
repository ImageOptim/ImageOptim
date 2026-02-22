#!/bin/bash
# Build jpegli + highway as universal static libraries for macOS.
# Called from Xcode's "Run Script" build phase in jpeg.xcodeproj.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_ROOT="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/build/lib"

# Use Xcode's deployment target if available, otherwise default
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"
export MACOSX_DEPLOYMENT_TARGET

ARCHS=(arm64 x86_64)

mkdir -p "$OUTPUT_DIR"

# Check if we need to rebuild
MARKER="$OUTPUT_DIR/.build_marker"
if [ -f "$MARKER" ] && [ -f "$OUTPUT_DIR/libjpegli-static.a" ] && [ -f "$OUTPUT_DIR/libhwy.a" ]; then
    MARKER_TIME=$(stat -f %m "$MARKER" 2>/dev/null || echo 0)
    CMAKE_TIME=$(stat -f %m "$SRC_DIR/lib/jpegli.cmake" 2>/dev/null || echo 1)
    WRAPPER_TIME=$(stat -f %m "$SRC_DIR/lib/jpegli/libjpeg_wrapper.cc" 2>/dev/null || echo 1)
    MAX_SRC_TIME=$((CMAKE_TIME > WRAPPER_TIME ? CMAKE_TIME : WRAPPER_TIME))
    if [ "$MARKER_TIME" -ge "$MAX_SRC_TIME" ]; then
        echo "jpegli: already built (up to date)"
        exit 0
    fi
fi

build_arch() {
    local ARCH=$1
    local BUILD_DIR="$BUILD_ROOT/$ARCH"

    echo "jpegli: building for $ARCH..."
    mkdir -p "$BUILD_DIR"

    cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_CXX_FLAGS="-fPIC" \
        -DJPEGXL_ENABLE_JPEGLI=ON \
        -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF \
        -DJPEGXL_ENABLE_TOOLS=OFF \
        -DJPEGXL_ENABLE_MANPAGES=OFF \
        -DJPEGXL_ENABLE_BENCHMARK=OFF \
        -DJPEGXL_ENABLE_EXAMPLES=OFF \
        -DJPEGXL_ENABLE_DOXYGEN=OFF \
        -DJPEGXL_ENABLE_SKCMS=OFF \
        -DBUILD_TESTING=OFF \
        -DJPEGXL_ENABLE_SJPEG=OFF \
        -DJPEGXL_ENABLE_OPENEXR=OFF \
        -DJPEGXL_STATIC=ON \
        -DJPEGXL_BUNDLE_LIBPNG=OFF \
        -G Ninja \
        2>&1 | tail -5

    cmake --build "$BUILD_DIR" --target jpegli-static hwy --config Release -- -j"$(sysctl -n hw.ncpu)" 2>&1 | tail -5

    # Compile the libjpeg-compatible wrapper (provides jpeg_* C symbols)
    echo "jpegli: compiling wrapper for $ARCH..."
    local WRAPPER_OBJ="$BUILD_DIR/libjpeg_wrapper.o"
    xcrun clang++ -c -std=c++17 -fPIC -O2 \
        -arch "$ARCH" \
        -mmacosx-version-min="$MACOSX_DEPLOYMENT_TARGET" \
        -I"$BUILD_DIR/lib/include/jpegli" \
        -I"$SRC_DIR" \
        -I"$SRC_DIR/lib/include" \
        -I"$BUILD_DIR/lib/include" \
        -o "$WRAPPER_OBJ" \
        "$SRC_DIR/lib/jpegli/libjpeg_wrapper.cc"

    # Compile jutils_compat.c (provides utility functions for transupp.c/jpegtran)
    local COMPAT_OBJ="$BUILD_DIR/jutils_compat.o"
    xcrun clang -c -fPIC -O2 \
        -arch "$ARCH" \
        -mmacosx-version-min="$MACOSX_DEPLOYMENT_TARGET" \
        -I"$BUILD_DIR/lib/include/jpegli" \
        -o "$COMPAT_OBJ" \
        "$SCRIPT_DIR/jutils_compat.c"

    # Merge wrapper + compat objects into the jpegli static library
    local JPEGLI_LIB
    JPEGLI_LIB=$(find "$BUILD_DIR" -name "libjpegli-static.a" -type f | head -1)
    ar r "$JPEGLI_LIB" "$WRAPPER_OBJ" "$COMPAT_OBJ"
    ranlib "$JPEGLI_LIB"
}

for ARCH in "${ARCHS[@]}"; do
    build_arch "$ARCH"
done

echo "jpegli: creating universal binaries..."

# Create universal (fat) static libraries
lipo_create() {
    local LIB_NAME=$1
    local OUTPUT="$OUTPUT_DIR/$LIB_NAME"
    local INPUTS=()

    for ARCH in "${ARCHS[@]}"; do
        local LIB_PATH
        LIB_PATH=$(find "$BUILD_ROOT/$ARCH" -name "$LIB_NAME" -type f | head -1)
        if [ -z "$LIB_PATH" ]; then
            echo "ERROR: Could not find $LIB_NAME for $ARCH"
            exit 1
        fi
        INPUTS+=("$LIB_PATH")
    done

    lipo -create "${INPUTS[@]}" -output "$OUTPUT"
    echo "  Created: $OUTPUT"
}

lipo_create "libjpegli-static.a"
lipo_create "libhwy.a"

# Copy headers from the build output for consumers
HEADER_DIR="$SCRIPT_DIR/build/include"
mkdir -p "$HEADER_DIR"

# Use arm64 build as reference for generated headers
ARM64_BUILD="$BUILD_ROOT/arm64"
if [ -d "$ARM64_BUILD/lib/include/jpegli" ]; then
    cp -f "$ARM64_BUILD/lib/include/jpegli/jconfig.h" "$HEADER_DIR/"
    cp -f "$ARM64_BUILD/lib/include/jpegli/jpeglib.h" "$HEADER_DIR/"
    cp -f "$ARM64_BUILD/lib/include/jpegli/jmorecfg.h" "$HEADER_DIR/"
fi

# Also copy jerror.h from libjpeg-turbo (needed by consumers)
cp -f "$SRC_DIR/third_party/libjpeg-turbo/jerror.h" "$HEADER_DIR/"

touch "$MARKER"
echo "jpegli: build complete."
