# ImageOptim

[ImageOptim](https://imageoptim.com) is a GUI for lossless image optimization tools: Zopfli, PNGOUT, [OxiPNG](https://lib.rs/crates/oxipng), AdvPNG, PNGCrush, [JPEGOptim](https://github.com/tjko/jpegoptim), Jpegtran, [Guetzli](https://github.com/google/guetzli), [Gifsicle](https://kornel.ski/lossygif), [SVGO](https://github.com/svg/svgo), [svgcleaner](https://github.com/RazrFalcon/svgcleaner) and [MozJPEG](https://github.com/mozilla/mozjpeg).

## Changelog

### v1.9.5 (2025-03-11)

**Apple Silicon Support**
- Universal binary support for Apple Silicon (arm64) and Intel (x86_64) processors
- Release builds produce a single app that runs natively on both architectures

**Dependency Consolidation**
- All dependency files unified locally for easy compilation
- Added libzopfli.a and libdeflate.a for advpng
- Pre-built binaries included in submodules

**Release Assets**
- DMG: `ImageOptim-1.9.5.dmg` for distribution
- tar.bz2: `ImageOptim1.9.5.tar.bz2` for Sparkle updates

### v1.9.5 (2025-03-11)

**Version bump** – build and release tooling updates.

### v1.9.4 (2025-03-11)

**Apple Silicon (arm64) Support**
- Universal binary support for Apple Silicon (arm64) and Intel (x86_64) processors
- Release builds produce a single app that runs natively on both architectures

**Build System**
- `imageoptim/release.xcconfig`: Add `ARCHS = arm64 x86_64` for universal binaries
- `jpegoptim/jpeg-6b/jpeg.xcodeproj`: Update `VALID_ARCHS` and `ARCHS` from legacy `i386 ppc x86_64` to `arm64 x86_64`
- `advpng`: Add libzopfli.a and libdeflate.a linking; run `./configure && make` in advpng for dependencies
- One-step build script: `./scripts/build-dmg.sh` builds and creates DMG

**Release Assets**
- DMG: `ImageOptim-1.9.5.dmg` for distribution
- tar.bz2: `ImageOptim1.9.5.tar.bz2` for Sparkle updates

## Building

Requires:

* Xcode
* [Rust](https://rust-lang.org/) installed via [rustup](https://www.rustup.rs/) (not Homebrew).

```sh
git clone --recursive https://imageoptim.com ImageOptim
cd ImageOptim
```

To get started, open `imageoptim/ImageOptim.xcodeproj`. It will automatically download and build all subprojects when run in Xcode.

In case of build errors, these sometimes help:

```sh
git submodule update --init
```

```sh
cd gifsicle # or pngquant
make clean
make
```

## Testing

Run product tests:

```sh
# Run BackendTests unit tests (PNG/JPEG/GIF/SVG optimization)
./scripts/run-tests.sh --quick

# Run full test suite
./scripts/run-tests.sh --all

# Integration test (requires build first)
./scripts/integration-test.sh
```

Or in Xcode: `Product` → `Test` (⌘U)

## Release

One-step build and DMG creation:

```sh
./scripts/build-dmg.sh
```

Full release (build, tag, push to GitHub, create release with DMG + tar.bz2):

```sh
# Requires: gh CLI (brew install gh), authenticated with GitHub
./scripts/release-github.sh [VERSION]
```

Outputs are saved to `release-<VERSION>/` locally and uploaded as GitHub release assets.
