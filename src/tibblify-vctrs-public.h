#ifndef TIBBLIFY_VCTRS_PUBLIC_H
#define TIBBLIFY_VCTRS_PUBLIC_H

#include "tibblify.h"
#include <vctrs.h>

static inline R_len_t vec_size(SEXP x) {
  return short_vec_size(x);
}

#endif
