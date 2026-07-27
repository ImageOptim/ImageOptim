/* Internal libjpeg-turbo configuration, normally generated from
 * jconfigint.h.in by CMake. jpegli only configures libjpeg-turbo's *public*
 * headers, so nothing produces this one, but libjpeg-turbo's jinclude.h
 * includes it — and jpegtran compiles transupp.c/cdjpeg.c/rdswitch.c straight
 * out of that tree. Kept checked in alongside jconfig.h, which is maintained
 * the same way.
 *
 * The values below are for the vendored libjpeg-turbo, built by clang for
 * 64-bit macOS (both arm64 and x86_64, where size_t is 8 bytes either way).
 */

/* libjpeg-turbo build number */
#define BUILD  "20260601"

/* Compiler's inline keyword */
#undef inline

/* How to obtain function inlining. */
#define INLINE  __inline__ __attribute__((always_inline))

/* How to obtain thread-local storage */
#define THREAD_LOCAL  __thread

/* Define to the full name of this package. */
#define PACKAGE_NAME  "libjpeg-turbo"

/* Version number of package */
#define VERSION  "2.1.5.1"

/* The size of `size_t', as computed by sizeof. */
#define SIZEOF_SIZE_T  8

/* Define if your compiler has __builtin_ctzl() and sizeof(unsigned long) == sizeof(size_t). */
#define HAVE_BUILTIN_CTZL

#if defined(__has_attribute)
#if __has_attribute(fallthrough)
#define FALLTHROUGH  __attribute__((fallthrough));
#else
#define FALLTHROUGH
#endif
#else
#define FALLTHROUGH
#endif
