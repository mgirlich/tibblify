// oriented on https://github.com/r-lib/vctrs/blob/e88a3e28822fa5bf925048e6bd0b10315f7bd9af/src/type-info.c
#include "tibblify.h"
#include "vctrs-type-info.h"
#include "vctrs-utils-dispatch.h"

bool is_data_frame(r_obj* x) {
  return
    r_typeof(x) == R_TYPE_list &&
    class_type_is_data_frame(class_type(x));
}

bool is_bare_data_frame(r_obj* x) {
  return class_type(x) == VCTRS_CLASS_bare_data_frame;
}

static
enum vctrs_type vec_base_typeof(r_obj* x, bool proxied) {
  switch (r_typeof(x)) {
  // Atomic types are always vectors
  case R_TYPE_null: return VCTRS_TYPE_null;
  case R_TYPE_logical: return VCTRS_TYPE_logical;
  case R_TYPE_integer: return VCTRS_TYPE_integer;
  case R_TYPE_double: return VCTRS_TYPE_double;
  case R_TYPE_complex: return VCTRS_TYPE_complex;
  case R_TYPE_character: return VCTRS_TYPE_character;
  case R_TYPE_raw: return VCTRS_TYPE_raw;
  case R_TYPE_list:
    // Bare lists and data frames are vectors
    if (!r_is_object(x)) return VCTRS_TYPE_list;
    if (is_data_frame(x)) return VCTRS_TYPE_dataframe;
    // S3 lists are only vectors if they are proxied
    if (proxied || r_inherits(x, "list")) return VCTRS_TYPE_list;
    // fallthrough
  default: return VCTRS_TYPE_scalar;
  }
}

enum vctrs_type vec_typeof(r_obj* x) {
  // Check for unspecified vectors before `vec_base_typeof()` which
  // allows vectors of `NA` to pass through as `VCTRS_TYPE_logical`
  if (vec_is_unspecified(x)) {
    return VCTRS_TYPE_unspecified;
  }

  if (!r_is_object(x) || r_class(x) == r_null) {
    return vec_base_typeof(x, false);
  }

  // Bare data frames are treated as a base atomic type. Subclasses of
  // data frames are treated as S3 to give them a chance to be proxied
  // or implement their own methods for cast, type2, etc.
  if (is_bare_data_frame(x)) {
    return VCTRS_TYPE_dataframe;
  }

  return VCTRS_TYPE_s3;
}

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
