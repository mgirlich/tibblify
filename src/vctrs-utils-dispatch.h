// oriented on https://github.com/r-lib/vctrs/blob/e88a3e28822fa5bf925048e6bd0b10315f7bd9af/src/utils-dispatch.h

#ifndef VCTRS_UTILS_DISPATCH_H
#define VCTRS_UTILS_DISPATCH_H

#include "tibblify-core.h"

enum vctrs_class_type {
  VCTRS_CLASS_list,
  VCTRS_CLASS_data_frame,
  VCTRS_CLASS_bare_asis,
  VCTRS_CLASS_bare_data_frame,
  VCTRS_CLASS_bare_tibble,
  VCTRS_CLASS_bare_factor,
  VCTRS_CLASS_bare_ordered,
  VCTRS_CLASS_bare_date,
  VCTRS_CLASS_bare_posixct,
  VCTRS_CLASS_bare_posixlt,
  VCTRS_CLASS_unknown,
  VCTRS_CLASS_none
};

enum vctrs_class_type class_type(r_obj* x);

#endif
