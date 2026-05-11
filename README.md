# ImageOptim

[ImageOptim](https://imageoptim.com) is a GUI for lossless image optimization tools: Zopfli, PNGOUT, [OxiPNG](https://lib.rs/crates/oxipng), AdvPNG, PNGCrush, [JPEGOptim](https://github.com/tjko/jpegoptim), Jpegtran, [Guetzli](https://github.com/google/guetzli), [Gifsicle](https://kornel.ski/lossygif), [SVGO](https://github.com/svg/svgo), [svgcleaner](https://github.com/RazrFalcon/svgcleaner) and [MozJPEG](https://github.com/mozilla/mozjpeg).

This project keeps the native AppKit/XIB workflow and currently targets macOS 13+ on Apple Silicon only (`arm64`). Intel Macs and older macOS releases are no longer supported by this build configuration.

## Download

Prebuilt Apple Silicon builds are published on GitHub Releases:

* [Download the latest ImageOptim build](https://github.com/a-j-n/ImageOptimizer/releases/latest)
* [Browse all builds](https://github.com/a-j-n/ImageOptimizer/releases)

Each build is for macOS 13+ on Apple Silicon (`arm64`). If the latest release does not include an app archive yet, build the app locally with the steps below.

## Main window

The refreshed main window keeps the table-based optimization queue, with:

* Native toolbar actions for Add Files, Stop, Retry Failed, Optimize Again, Clear Done, and Settings.
* Queue totals for Total, Done, Running, Remaining, and Failed, plus determinate progress.
* Queue filters for All, Running, Done, and Failed.
* Task-state labels such as Queued, OxiPng, JpegOptim, Optimized, No change, and Failed.
* A drag-and-drop empty state, a clearer task table, and a selection details strip.

## Building

Requires:

* macOS 13+ on an Apple Silicon Mac.
* Xcode with a macOS 13 SDK or newer.
* [Rust](https://rust-lang.org/) installed via [rustup](https://www.rustup.rs/) (not Homebrew).
* Node at `/opt/homebrew/bin/node` for SVGO support.

```sh
git clone --recursive git@github.com:a-j-n/ImageOptimizer.git
cd ImageOptimizer
```

To get started, open `imageoptim/ImageOptim.xcodeproj`. It will automatically download and build all subprojects when run in Xcode.

To build the Release app from the command line:

```sh
xcodebuild \
  -project imageoptim/ImageOptim.xcodeproj \
  -scheme ImageOptim \
  -configuration Release \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Release verification

Run the release verification script before shipping a build:

```sh
scripts/verify-release
```

It lints changed plist/strings files, validates `ImageOptim.xib`, builds Release for `arm64`, and checks the final `.app` plus bundled helpers with `lipo -archs`.

## Troubleshooting

In case of build errors, these sometimes help:

```sh
git submodule update --init
```

```sh
cd gifsicle # or pngquant
make clean
make
```

Some helper projects generate local build artifacts inside submodules. The repository ignores those files so normal helper builds do not dirty the main working tree.
