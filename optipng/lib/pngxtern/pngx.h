/*
 * pngx.h - libpng extensions.
 *
 * Copyright (C) 2001-2008 Cosmin Truta.
 * This software is distributed under the same licensing and warranty terms
 * as libpng.
 *
 * This file contains symbols used in OptiPNG/pngxtern and proposed for
 * addition to libpng.
 */


#ifndef PNGX_H
#define PNGX_H

#include "png.h"


/* PNGX_ASSERT and PNGX_ASSERT_MSG:
 * Hopefully, there will be a PNG_ASSERT in libpng someday.
 * Meanwhile, we provide a plain version, based on assert.
 */
#ifndef PNGX_ASSERT
#include <assert.h>
#define PNGX_ASSERT(cond) assert(cond)
#define PNGX_ASSERT_MSG(cond, msg) assert(cond)
#endif


#ifdef __cplusplus
extern "C" {
#endif


/* Store data into the info structure. */
extern PNG_EXPORT(void, pngx_set_compression_method)
   PNGARG((png_structp png_ptr, png_infop info_ptr, int compression_method));
extern PNG_EXPORT(void, pngx_set_filter_method)
   PNGARG((png_structp png_ptr, png_infop info_ptr, int filter_method));
extern PNG_EXPORT(void, pngx_set_interlace_method)
   PNGARG((png_structp png_ptr, png_infop info_ptr, int interlace_method));


/* Allocate memory for the row pointers.
 * Use filler to initialize the rows if it is non-negative.
 * On success return the newly-allocated row pointers.
 * On failure issue a png_error() or return NULL,
 * depending on the status of PNG_FLAG_MALLOC_NULL_MEM_OK.
 */
extern PNG_EXPORT(png_bytepp, pngx_malloc_rows)
   PNGARG((png_structp png_ptr, png_infop info_ptr, int filler));


#if PNG_LIBPNG_VER >= 10400

/* The support for I/O states is now integrated in libpng-1.4 */
#ifndef PNG_IO_STATE_SUPPORTED
#error This module requires libpng with PNG_IO_STATE_SUPPORTED
#endif

#define pngx_get_io_state       png_get_io_state
#define pngx_get_io_chunk_name  png_get_io_chunk_name
#define pngx_set_read_fn        png_set_read_fn
#define pngx_set_write_fn       png_set_write_fn
#define pngx_write_sig          png_write_sig

#define PNGX_IO_NONE            PNG_IO_NONE
#define PNGX_IO_READING         PNG_IO_READING
#define PNGX_IO_WRITING         PNG_IO_WRITING
#define PNGX_IO_SIGNATURE       PNG_IO_SIGNATURE
#define PNGX_IO_CHUNK_HDR       PNG_IO_CHUNK_HDR
#define PNGX_IO_CHUNK_DATA      PNG_IO_CHUNK_DATA
#define PNGX_IO_CHUNK_CRC       PNG_IO_CHUNK_CRC
#define PNGX_IO_MASK_OP         PNG_IO_MASK_OP
#define PNGX_IO_MASK_LOC        PNG_IO_MASK_LOC

#else /* PNG_LIBPNG_VER < 10400 */

/* Compatibility backports of functions added to libpng 1.4 */
extern PNG_EXPORT(png_uint_32,pngx_get_io_state)
   PNGARG((png_structp png_ptr));
extern PNG_EXPORT(png_bytep,pngx_get_io_chunk_name)
   PNGARG((png_structp png_ptr));
/* Note: although these backports have several limitations in comparison
 * to the actual libpng 1.4 functions, they work properly in OptiPNG,
 * as long as that they are used in conjunction with the wrappers below.
 */

/* Compatibility wrappers for old libpng functions */
extern PNG_EXPORT(void,pngx_set_read_fn) PNGARG((png_structp png_ptr,
   png_voidp io_ptr, png_rw_ptr read_data_fn));
extern PNG_EXPORT(void,pngx_set_write_fn) PNGARG((png_structp png_ptr,
   png_voidp io_ptr, png_rw_ptr write_data_fn, png_flush_ptr output_flush_fn));
extern PNG_EXPORT(void,pngx_write_sig) PNGARG((png_structp png_ptr));

/* Flags returned by png_get_io_state() */
#define PNGX_IO_NONE        0x0000  /* no I/O at this moment */
#define PNGX_IO_READING     0x0001  /* currently reading */
#define PNGX_IO_WRITING     0x0002  /* currently writing */
#define PNGX_IO_SIGNATURE   0x0010  /* currently at the file signature */
#define PNGX_IO_CHUNK_HDR   0x0020  /* currently at the chunk header */
#define PNGX_IO_CHUNK_DATA  0x0040  /* currently at the chunk data */
#define PNGX_IO_CHUNK_CRC   0x0080  /* currently at the chunk crc */
#define PNGX_IO_MASK_OP     0x000f  /* current operation: reading/writing */
#define PNGX_IO_MASK_LOC    0x00f0  /* current location: sig/hdr/data/crc */

#endif /* ?PNG_LIBPNG_VER >= 10400 */


#ifdef __cplusplus
}  /* extern "C" */
#endif


#endif /* PNGX_H */
