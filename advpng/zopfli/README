Zopfli Compression Algorithm is a compression library programmed in C to perform
very good, but slow, deflate or zlib compression.

The basic function to compress data is ZopfliCompress in zopfli.h. Use the
ZopfliOptions object to set parameters that affect the speed and compression.
Use the ZopfliInitOptions function to place the default values in the
ZopfliOptions first.

ZopfliCompress supports deflate, gzip and zlib output format with a parameter.
To support only one individual format, you can instead use ZopfliDeflate in
deflate.h, ZopfliZlibCompress in zlib_container.h or ZopfliGzipCompress in
gzip_container.h.

ZopfliDeflate creates a valid deflate stream in memory, see:
http://www.ietf.org/rfc/rfc1951.txt
ZopfliZlibCompress creates a valid zlib stream in memory, see:
http://www.ietf.org/rfc/rfc1950.txt
ZopfliGzipCompress creates a valid gzip stream in memory, see:
http://www.ietf.org/rfc/rfc1952.txt

This library can only compress, not decompress. Existing zlib or deflate
libraries can decompress the data.

zopfli_bin.c is separate from the library and contains an example program to
create very well compressed gzip files. Currently the makefile builds this
program with the library statically linked in.

The source code of Zopfli is under src/zopfli. Build instructions:

To build zopfli, compile all .c source files under src/zopfli to a single binary
with C, and link to the standard C math library, e.g.:
gcc src/zopfli/*.c -O2 -W -Wall -Wextra -Wno-unused-function -ansi -pedantic -lm -o zopfli

A makefile is provided as well, but only for linux. Use "make" to build the
binary, "make libzopfli" to build it as a shared library. For other platforms,
please use the build instructions above instead.

Zopfli Compression Algorithm was created by Lode Vandevenne and Jyrki
Alakuijala, based on an algorithm by Jyrki Alakuijala.
