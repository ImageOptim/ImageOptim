/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

#ifndef GIFSICLE_CONFIG_H
#define GIFSICLE_CONFIG_H

/* Define when using the debugging malloc library. */
/* #undef DMALLOC */

/* Define to the number of arguments to gettimeofday (gifview only). */
/* #undef GETTIMEOFDAY_PROTO */

/* Define if GIF LZW compression is off. */
/* #undef GIF_UNGIF */

/* Define if intXX_t types are not available. */
/* #undef HAVE_FAKE_INT_TYPES */

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `mkstemp' function. */
#define HAVE_MKSTEMP 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strtoul' function. */
#define HAVE_STRTOUL 1

/* Define to 1 if you have the <sys/select.h> header file. */
#define HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if the system has the type `uintptr_t'. */
#define HAVE_UINTPTR_T 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define if you have u_intXX_t types but not uintXX_t types. */
/* #undef HAVE_U_INT_TYPES */

/* Define to write GIFs to stdout even when stdout is a terminal. */
/* #undef OUTPUT_GIF_TO_TERMINAL */

/* Name of package */
#define PACKAGE "gifsicle"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME ""

/* Define to the full name and version of this package. */
#define PACKAGE_STRING ""

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME ""

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION ""

/* Pathname separator character ('/' on Unix). */
#define PATHNAME_SEPARATOR '/'

/* Define to a function that returns a random number. */
#define RANDOM random

/* The size of `unsigned int', as computed by sizeof. */
#define SIZEOF_UNSIGNED_INT 4

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Version number of package */
#define VERSION "1.58"

/* Define if X is not available. */
#define X_DISPLAY_MISSING 1

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Use either the clean-failing malloc library in fmalloc.c, or the debugging
   malloc library in dmalloc.c. */
#ifdef DMALLOC
# include "dmalloc.h"
# define Gif_DeleteFunc		(&debug_free)
# define Gif_DeleteArrayFunc	(&debug_free)
#else
# include <stddef.h>
# define xmalloc(s)		fail_die_malloc((s),__FILE__,__LINE__)
# define xrealloc(p,s)		fail_die_realloc((p),(s),__FILE__,__LINE__)
# define xfree			free
void *fail_die_malloc(size_t, const char *, int);
void *fail_die_realloc(void *, size_t, const char *, int);
#endif

/* Prototype strerror if we don't have it. */
#ifndef HAVE_STRERROR
char *strerror(int errno);
#endif

#ifdef __cplusplus
}
/* Get rid of a possible inline macro under C++. */
# define inline inline
#endif

#endif /* GIFSICLE_CONFIG_H */
