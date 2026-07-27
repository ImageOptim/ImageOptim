/*
 * Compatibility shim providing libjpeg-turbo utility functions
 * that jpegli doesn't export but transupp.c/jpegtran need.
 * These are simple helper functions from libjpeg-turbo's jutils.c.
 */

#include <stdio.h>
#include <string.h>
#include "jpeglib.h"

long
jdiv_round_up(long a, long b)
{
  return (a + b - 1L) / b;
}

long
jround_up(long a, long b)
{
  a += b - 1L;
  return a - (a % b);
}

void
jcopy_block_row(JBLOCKROW input_row, JBLOCKROW output_row,
                JDIMENSION num_blocks)
{
  memcpy(output_row, input_row, num_blocks * (DCTSIZE2 * sizeof(JCOEF)));
}

void
jcopy_sample_rows(JSAMPARRAY input_array, int source_row,
                  JSAMPARRAY output_array, int dest_row, int num_rows,
                  JDIMENSION num_cols)
{
  JSAMPROW inptr, outptr;
  size_t count = (size_t)num_cols * sizeof(JSAMPLE);
  int row;

  input_array += source_row;
  output_array += dest_row;

  for (row = num_rows; row > 0; row--) {
    inptr = *input_array++;
    outptr = *output_array++;
    memcpy(outptr, inptr, count);
  }
}
