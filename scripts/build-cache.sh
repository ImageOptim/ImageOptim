#!/bin/bash

# Resolved when this file is sourced so the functions below don't depend on the
# caller keeping a variable pointing back at this script.
BUILD_CACHE_HELPER_PATH="${BASH_SOURCE[0]}"

# Produces a stable cache key from the build scripts, configuration, toolchain,
# source revisions, and any local source edits.
build_cache_signature() {
    local SCRIPT_PATH=$1
    local CONFIGURATION=$2
    shift 2

    {
        printf 'configuration:%s\n' "$CONFIGURATION"
        shasum -a 256 "$BUILD_CACHE_HELPER_PATH" "$SCRIPT_PATH"
        printf 'SDKROOT=%s\n' "${SDKROOT:-}"
        printf 'DEVELOPER_DIR=%s\n' "${DEVELOPER_DIR:-}"
        printf 'CC=%s\n' "${CC:-}"
        printf 'CXX=%s\n' "${CXX:-}"
        printf 'CFLAGS=%s\n' "${CFLAGS:-}"
        printf 'CXXFLAGS=%s\n' "${CXXFLAGS:-}"
        printf 'LDFLAGS=%s\n' "${LDFLAGS:-}"
        command -v cmake
        cmake --version | head -1
        command -v ninja
        ninja --version
        xcrun --show-sdk-path
        xcrun clang --version | head -1

        local SOURCE_DIR
        for SOURCE_DIR in "$@"; do
            (
                cd "$SOURCE_DIR" || exit 1
                printf 'source:%s\n' "$SOURCE_DIR"
                git rev-parse HEAD
                git status --porcelain=v2 --untracked-files=all
                git diff --no-ext-diff --binary HEAD
                git ls-files --others --exclude-standard |
                    while IFS= read -r FILE_PATH; do
                        printf 'untracked:%s\n' "$FILE_PATH"
                        git hash-object -- "$FILE_PATH"
                    done
                git submodule foreach --quiet --recursive '
                    printf "submodule:%s\n" "$displaypath"
                    git rev-parse HEAD
                    git status --porcelain=v2 --untracked-files=all
                    git diff --no-ext-diff --binary HEAD
                    git ls-files --others --exclude-standard |
                        while IFS= read -r FILE_PATH; do
                            printf "untracked:%s\n" "$FILE_PATH"
                            git hash-object -- "$FILE_PATH"
                        done
                '
            )
        done
    } | shasum -a 256 | awk '{print $1}'
}

build_cache_is_current() {
    local MARKER=$1
    local SIGNATURE=$2
    shift 2

    [ -f "$MARKER" ] || return 1

    local OUTPUT
    for OUTPUT in "$@"; do
        [ -f "$OUTPUT" ] || return 1
    done

    [ "$(cat "$MARKER")" = "$SIGNATURE" ]
}

build_cache_write() {
    printf '%s\n' "$2" > "$1"
}
