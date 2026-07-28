# ImageOptim

[ImageOptim](https://imageoptim.com) is a GUI for lossless image optimization tools: PNGOUT, [OxiPNG](https://lib.rs/crates/oxipng), AdvPNG, PNGCrush, [JPEGOptim](https://github.com/tjko/jpegoptim), Jpegtran, [Gifsicle](https://kornel.ski/lossygif), [SVGO](https://github.com/svg/svgo), [Jpegli](https://github.com/google/jpegli), [libavif](https://github.com/AOMediaCodec/libavif) and [libjxl](https://github.com/libjxl/libjxl).

## Building

Requires:

* Xcode
* [Rust](https://rust-lang.org/) installed via [rustup](https://www.rustup.rs/) (not Homebrew).
* [CMake](https://cmake.org/) and [Ninja](https://ninja-build.org/) to build Jpegli (`brew install cmake ninja`).

```sh
git clone https://imageoptim.com ImageOptim
cd ImageOptim
git submodule update --init
```

Don't clone recursively: libjxl's own submodules include a large test-data
repository and backends this build doesn't use, and `libjxl/Makefile`
initialises only the ones it needs. The other subprojects with nested
submodules fetch them from their own makefiles too.

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
