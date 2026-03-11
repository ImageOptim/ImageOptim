#!/bin/bash
#
# ImageOptim product test script
# Runs BackendTests unit tests to verify image optimization core functionality
#
# Usage:
#   ./scripts/run-tests.sh           # run all tests
#   ./scripts/run-tests.sh --quick  # quick test (BackendTests only)
#   ./scripts/run-tests.sh --list   # list available tests
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/imageoptim/ImageOptim.xcodeproj"
SCHEME="ImageOptim"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check Xcode environment
check_prerequisites() {
    if ! command -v xcodebuild &>/dev/null; then
        error "xcodebuild not found. Ensure Xcode and command line tools are installed"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_PATH" ]; then
        error "Project path does not exist: $PROJECT_PATH"
        exit 1
    fi
    
    info "Project path: $PROJECT_ROOT"
}

# Run BackendTests
run_backend_tests() {
    info "Running BackendTests (PNG/JPEG/GIF/SVG optimization core logic)..."
    
    # If scheme has no test action configured, run Product → Test in Xcode first to generate it
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -only-testing:BackendTests \
        -resultBundlePath "$PROJECT_ROOT/build/TestResults" \
        2>&1 | tee "$PROJECT_ROOT/build/test-output.log" || true
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        info "BackendTests passed ✓"
    else
        error "BackendTests failed (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Run all tests
run_all_tests() {
    info "Running full test suite..."
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -resultBundlePath "$PROJECT_ROOT/build/TestResults" \
        2>&1 | tee "$PROJECT_ROOT/build/test-output.log" || true
    
    return ${PIPESTATUS[0]}
}

# List available tests
list_tests() {
    info "Available test targets:"
    xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep -q . && \
        echo "  - BackendTests (PNG/JPEG/GIF/SVG optimization)"
}

# Main flow
main() {
    cd "$PROJECT_ROOT"
    mkdir -p build
    
    check_prerequisites
    
    case "${1:-}" in
        --list)
            list_tests
            ;;
        --quick)
            run_backend_tests
            exit $?
            ;;
        --all)
            run_all_tests
            exit $?
            ;;
        *)
            # Default: run BackendTests
            run_backend_tests
            exit $?
            ;;
    esac
}

main "$@"
