#ifndef TIBBLIFY_VCTRS_PUBLIC_H
#define TIBBLIFY_VCTRS_PUBLIC_H

#include "tibblify.h"
#include <vctrs.h>

static inline R_len_t vec_size(SEXP x) {
  return short_vec_size(x);
}

static inline r_obj* vec_recycle(SEXP x, R_len_t n) {
  return short_vec_recycle(x, n);
}

#endif
