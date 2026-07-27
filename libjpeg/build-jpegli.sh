#!/bin/bash
# Build jpegli + highway as universal static libraries for macOS.
# Called from Xcode's "Run Script" build phase in jpeg.xcodeproj.
#
# jpegli lives in its own repository (google/jpegli); it was removed from
# libjxl in March 2026. Its CMake options are the JPEGLI_* family, which are
# the renamed equivalents of libjxl's old JPEGXL_* options.

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

BUILD_CACHE_HELPER="$SCRIPT_DIR/../scripts/build-cache.sh"
source "$BUILD_CACHE_HELPER"

MARKER="$OUTPUT_DIR/.build_marker"
BUILD_SIGNATURE=$(build_cache_signature \
    "$0" \
    "deployment-target=$MACOSX_DEPLOYMENT_TARGET;archs=${ARCHS[*]}" \
    "$SRC_DIR")
if build_cache_is_current "$MARKER" "$BUILD_SIGNATURE" \
    "$OUTPUT_DIR/libjpegli-static.a" "$OUTPUT_DIR/libhwy.a"; then
    echo "jpegli: already built (up to date)"
    exit 0
fi

build_arch() {
    local ARCH=$1
    local BUILD_DIR="$BUILD_ROOT/$ARCH"

    echo "jpegli: building for $ARCH..."
    mkdir -p "$BUILD_DIR"

    # JPEGLI_ENABLE_JPEGLI_LIBJPEG is off because we link a static library and
    # merge the libjpeg-compatible wrapper in by hand below, rather than
    # shipping jpegli's drop-in libjpeg shared library.
    cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_CXX_FLAGS="-fPIC" \
        -DBUILD_SHARED_LIBS=OFF \
        -DJPEGLI_STATIC=ON \
        -DJPEGLI_ENABLE_JPEGLI_LIBJPEG=OFF \
        -DJPEGLI_ENABLE_TOOLS=OFF \
        -DJPEGLI_ENABLE_DEVTOOLS=OFF \
        -DJPEGLI_ENABLE_MANPAGES=OFF \
        -DJPEGLI_ENABLE_BENCHMARK=OFF \
        -DJPEGLI_ENABLE_DOXYGEN=OFF \
        -DJPEGLI_ENABLE_SKCMS=OFF \
        -DJPEGLI_ENABLE_SJPEG=OFF \
        -DJPEGLI_ENABLE_OPENEXR=OFF \
        -DJPEGLI_ENABLE_JNI=OFF \
        -DJPEGLI_ENABLE_FUZZERS=OFF \
        -DJPEGLI_BUNDLE_LIBPNG=OFF \
        -DBUILD_TESTING=OFF \
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
    if [ -z "$JPEGLI_LIB" ]; then
        echo "ERROR: libjpegli-static.a not found in $BUILD_DIR" >&2
        exit 1
    fi
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
            echo "ERROR: Could not find $LIB_NAME for $ARCH" >&2
            exit 1
        fi
        INPUTS+=("$LIB_PATH")
    done

    lipo -create "${INPUTS[@]}" -output "$OUTPUT"
    echo "  Created: $OUTPUT"
}

lipo_create "libjpegli-static.a"
lipo_create "libhwy.a"

# Copy the generated headers for consumers. jpegli configures these into
# <build>/lib/include/jpegli, using arm64 as the reference build.
HEADER_DIR="$SCRIPT_DIR/build/include"
mkdir -p "$HEADER_DIR"

GENERATED_INCLUDE="$BUILD_ROOT/arm64/lib/include/jpegli"
if [ ! -d "$GENERATED_INCLUDE" ]; then
    echo "ERROR: generated headers not found at $GENERATED_INCLUDE" >&2
    exit 1
fi
cp -f "$GENERATED_INCLUDE/jconfig.h" "$HEADER_DIR/"
cp -f "$GENERATED_INCLUDE/jpeglib.h" "$HEADER_DIR/"
cp -f "$GENERATED_INCLUDE/jmorecfg.h" "$HEADER_DIR/"

# jerror.h is not generated; take it from the vendored libjpeg-turbo.
cp -f "$SRC_DIR/third_party/libjpeg-turbo/jerror.h" "$HEADER_DIR/"

# jpegtran compiles jpegtran.c/transupp.c/cdjpeg.c/rdswitch.c straight out of
# the vendored libjpeg-turbo tree, and those need jversion.h. jpegli only
# configures libjpeg-turbo's public headers, so generate it here from the
# template the same way libjpeg-turbo's own CMake would.
COPYRIGHT_YEAR="$(sed -n 's/^set(COPYRIGHT_YEAR "\(.*\)")/\1/p' \
    "$SRC_DIR/third_party/libjpeg-turbo/CMakeLists.txt" | head -1)"
if [ -z "$COPYRIGHT_YEAR" ]; then
    echo "ERROR: could not read COPYRIGHT_YEAR from libjpeg-turbo's CMakeLists.txt" >&2
    exit 1
fi
sed "s/@COPYRIGHT_YEAR@/$COPYRIGHT_YEAR/g" \
    "$SRC_DIR/third_party/libjpeg-turbo/jversion.h.in" > "$HEADER_DIR/jversion.h"

# jpegli's build may drop a generated header in the source root; remove it
# so the submodule doesn't become dirty after a normal app build.
rm -f "$SRC_DIR/jpeglib.h"

build_cache_write "$MARKER" "$BUILD_SIGNATURE"
echo "jpegli: build complete."
