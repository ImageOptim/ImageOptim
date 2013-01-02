/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the `m' library (-lm). */
/* #undef HAVE_LIBM */

/* Define to 1 if you have the `z' library (-lz). */
#define HAVE_LIBZ 1

/* Define to 1 if you have the <malloc.h> header file. */
/* #undef HAVE_MALLOC_H */

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

/* Define to the sub-directory in which libtool stores uninstalled libraries.
 */
#define LT_OBJDIR ".libs/"

/* Name of package */
#define PACKAGE "libpng"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "png-mng-implement@lists.sourceforge.net"

/* Define to the full name of this package. */
#define PACKAGE_NAME "libpng"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libpng 1.4.4"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libpng"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "1.4.4"

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* Version number of package */
#define VERSION "1.4.4"

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef size_t */

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

#define PNG_WRITE_SUPPORTED
#define PNG_USE_LOCAL_ARRAYS
#define PNG_ALWAYS_EXTERN
#define PNG_READ_SUPPORTED
#define PNG_READ_16_TO_8_SUPPORTED
#define PNG_READ_EXPAND_SUPPORTED

#define PNG_NO_FIXED_POINT_SUPPORTED 1
#define PNG_FLOATING_POINT_SUPPORTED 1
#define PNG_READ_USER_TRANSFORM_SUPPORTED
#define PNG_WRITE_TRANSFORMS_NOT_SUPPORTED
/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef size_t */

#undef ZEXTERN
#define ZEXTERN

/* pngcrush */
#ifdef __ppc__
#  define PNG_NO_ASSEMBLER_CODE
#else
#  define PNG_MMX_CODE_SUPPORTED
#endif

#ifndef PNG_NO_ZALLOC_ZERO
#  define PNG_NO_ZALLOC_ZERO  /* speeds it up a little */
#endif

#undef PNG_USER_MEM_SUPPORTED /* disables debug malloc in pngcrush; required for optipng compat */

/*pngcrush can't compile without it :( */
#define PNG_MNG_FEATURES_SUPPORTED /* extra filter type */

#ifndef PNG_NO_LEGACY_SUPPORTED
#  define PNG_NO_LEGACY_SUPPORTED
#endif

#define PNG_READ_GRAY_TO_RGB_SUPPORTED

//#define PNG_NO_READ_hIST
//#define PNG_NO_WRITE_hIST
//#define PNG_NO_READ_pCAL
//#define PNG_NO_WRITE_pCAL
//#define PNG_NO_READ_sCAL
//#define PNG_NO_WRITE_sCAL
//#define PNG_NO_READ_sPLT
//#define PNG_NO_WRITE_sPLT
//#define PNG_NO_READ_tIME
//#define PNG_NO_WRITE_tIME
//#define PNG_NO_WRITE_zTXt
//#define PNG_NO_WRITE_sTER
//#define PNG_NO_READ_sTER
//#define PNG_NO_iTXt_SUPPORTED
//
//#define PNG_NO_INFO_IMAGE
//#define PNG_EASY_ACCESS
//#define PNG_NO_READ_DITHER
//#define PNG_NO_READ_EMPTY_PLTE
//#define PNG_NO_WRITE_TRANSFORMS
//#define PNG_NO_PROGRESSIVE_READ
//#define PNG_NO_WRITE_WEIGHTED_FILTER
//#define PNG_NO_READ_COMPOSITED_NODIV
//#define PNG_NO_READ_PREMULTIPLY_ALPHA
//#define PNG_NO_READ_SWAP_ALPHA
//#define PNG_NO_READ_INVERT_ALPHA
//#define PNG_NO_READ_BGR
//#define PNG_NO_READ_SWAP
//#define PNG_NO_SET_USER_LIMITS

#define PNG_READ_STRIP_ALPHA_SUPPORTED
#define PNG_READ_FILLER_SUPPORTED
#define PNG_READ_PACK_SUPPORTED
#define PNG_READ_SHIFT_SUPPORTED
#define PNG_SETJMP_SUPPORTED

#define PNG_WRITE_PACK_SUPPORTED
#define PNG_WRITE_SHIFT_SUPPORTED
#define PNG_hIST_SUPPORTED
#define PNG_INFO_IMAGE_SUPPORTED

#undef PNG_ZBUF_SIZE
#define PNG_ZBUF_SIZE (1<<17)
#undef TOO_FAR
#define TOO_FAR 32768U



