// oriented on https://github.com/r-lib/vctrs/blob/e88a3e28822fa5bf925048e6bd0b10315f7bd9af/src/type-info.c
#include "tibblify.h"
#include "vctrs-type-info.h"

bool obj_is_list(r_obj* x) {
  // Require `x` to be a list internally
  if (r_typeof(x) != R_TYPE_list) {
    return false;
  }

  // Unclassed R_TYPE_list are lists
  if (!r_is_object(x)) {
    return true;
  }

  const enum vctrs_class_type type = class_type(x);

  // Classed R_TYPE_list are only lists if the last class is explicitly `"list"`
  // or if it is a bare "AsIs" type
  return (type == VCTRS_CLASS_list) || (type == VCTRS_CLASS_bare_asis);
}
