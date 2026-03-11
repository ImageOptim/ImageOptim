#!/bin/bash
#
# ImageOptim integration test script
# Tests packaged optimization tools (jpegoptim, gifsicle, oxipng, etc.) after build
#
# Usage:
#   ./scripts/integration-test.sh
#   Or build first: xcodebuild -project imageoptim/ImageOptim.xcodeproj -scheme ImageOptim build
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_PATH="$BUILD_DIR/Release/ImageOptim.app"

# Find tools in build output
find_tool() {
    local name=$1
    local path
    path=$(find "$PROJECT_ROOT" -name "$name" -type f 2>/dev/null | head -1)
    if [ -n "$path" ]; then
        echo "$path"
        return 0
    fi
    # Check inside app bundle
    if [ -d "$APP_PATH" ]; then
        path=$(find "$APP_PATH" -name "$name" -type f 2>/dev/null | head -1)
        [ -n "$path" ] && echo "$path" && return 0
    fi
    return 1
}

run_test() {
    local name=$1
    local cmd=$2
    echo -n "  Testing $name ... "
    if eval "$cmd" >/dev/null 2>&1; then
        echo "✓"
        return 0
    else
        echo "✗"
        return 1
    fi
}

main() {
    echo "=== ImageOptim Integration Test ==="
    echo ""

    # Create temporary test files
    TEST_DIR=$(mktemp -d)
    trap "rm -rf $TEST_DIR" EXIT

    # Create simple PNG (1x1 red pixel)
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' > "$TEST_DIR/test.png"

    # Create simple JPEG (convert from PNG using sips)
    sips -s format jpeg "$TEST_DIR/test.png" --out "$TEST_DIR/test.jpg" 2>/dev/null || true

    # Create simple GIF
    python3 -c "
gif = bytes([0x47,0x49,0x46,0x38,0x39,0x61,0x01,0x00,0x01,0x00,0x80,0x00,0x00,0xff,0x00,0x00,0x21,0xf9,0x04,0x01,0x00,0x00,0x00,0x00,0x2c,0x00,0x00,0x00,0x00,0x01,0x00,0x01,0x00,0x00,0x02,0x02,0x44,0x01,0x00,0x3b])
open('$TEST_DIR/test.gif', 'wb').write(gif)
" 2>/dev/null || true

    PASSED=0
    FAILED=0

    # Test jpegoptim
    if JPEGOPTIM=$(find_tool jpegoptim); then
        if run_test "jpegoptim" "[ -f '$TEST_DIR/test.jpg' ] && '$JPEGOPTIM' --help >/dev/null 2>&1"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    else
        echo "  Skipping jpegoptim (not found)"
    fi

    # Test gifsicle
    if GIFSICLE=$(find_tool gifsicle); then
        if run_test "gifsicle" "[ -f '$TEST_DIR/test.gif' ] && '$GIFSICLE' --help >/dev/null 2>&1"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    else
        echo "  Skipping gifsicle (not found)"
    fi

    # Test oxipng
    if OXIPNG=$(find_tool oxipng); then
        if run_test "oxipng" "'$OXIPNG' --help >/dev/null 2>&1"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    else
        echo "  Skipping oxipng (not found)"
    fi

    # Test advpng
    if ADVPNG=$(find_tool advpng); then
        if run_test "advpng" "'$ADVPNG' --help >/dev/null 2>&1"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    else
        echo "  Skipping advpng (not found)"
    fi

    echo ""
    echo "Result: $PASSED passed, $FAILED failed"

    if [ $FAILED -gt 0 ]; then
        echo "Hint: Run 'xcodebuild -project imageoptim/ImageOptim.xcodeproj -scheme ImageOptim build' first"
        exit 1
    fi

    exit 0
}

main "$@"
