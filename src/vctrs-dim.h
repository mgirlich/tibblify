#ifndef VCTRS_DIM_H
#define VCTRS_DIM_H

#include "tibblify-core.h"
#include "vctrs-utils.h"

static inline bool has_dim(SEXP x) {
  return ATTRIB(x) != R_NilValue && r_dim(x) != R_NilValue;
}

#endif
