# ImageOptim

[ImageOptim](https://imageoptim.com) is a GUI for lossless image optimization tools: PNGOUT, AdvPNG, Pngcrush, [OxiPNG](https://crates.rs/crates/oxipng), JpegOptim, [MozJPEG](https://github.com/mozilla/mozjpeg), [Gifsicle](https://kornel.ski/lossygif), SVGO, and [svgcleaner](https://github.com/RazrFalcon/svgcleaner).

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
