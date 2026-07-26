/* Minimal config.h for the libpng+zlib target.
 *
 * libpng >= 1.5 takes its feature configuration from pnglibconf.h (we ship
 * libpng's own scripts/pnglibconf.h.prebuilt), so this file only carries the
 * autoconf HAVE_* probes that pngpriv.h looks for when HAVE_CONFIG_H is set.
 * The PNG_*_SUPPORTED defines that used to live here configured libpng 1.4
 * and have no effect from 1.5 onwards.
 */

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the `z' library (-lz). */
#define HAVE_LIBZ 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* Define to 1 if you have the `pow' function. */
#define HAVE_POW 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Name of package */
#define PACKAGE "libpng"
#define PACKAGE_NAME "libpng"
#define PACKAGE_TARNAME "libpng"
#define PACKAGE_BUGREPORT "png-mng-implement@lists.sourceforge.net"
#define PACKAGE_URL ""
