#include "tibblify.h"
#include "utils.h"

static inline
bool vec_is_list(r_obj* x) {
  return r_typeof(x) == R_TYPE_list && (r_class(x) == r_null || r_inherits(x, "list"));
}


bool is_object(r_obj* x) {
  // TODO unsure if it needs to be this strict
  if (!(vec_is_list(x))) {
    return false;
  }

  if (r_length(x) == 0) {
    return true;
  }

  if (!r_is_named(x)) {
    return false;
  }

  r_obj* nms = r_names(x);
  if (r_chr_has(nms, CHAR(r_globals.na_str))) {
    return false;
  }

  // TODO use vctrs when exported?
  if (Rf_any_duplicated(nms, false)) {
    return false;
  }

  return true;
}

r_obj* ffi_is_object(r_obj* x) {
  return r_lgl(is_object(x));
}

bool is_object_list(r_obj* x) {
  if (r_typeof(x) != R_TYPE_list) {
    return false;
  }

  if (is_data_frame(x)) {
    return true;
  }

  // TODO unsure if it needs to be this strict
  if (!(vec_is_list(x))) {
    return false;
  }

  r_ssize n = r_length(x);
  r_obj* const * v_x = r_list_cbegin(x);
  for (r_ssize i = 0; i < n; ++i) {
    r_obj* x_i = v_x[i];
    if (x_i != r_null && !is_object(x_i)) {
      return false;
    }
  }

  return true;
}

r_obj* ffi_is_object_list(r_obj* x) {
  return r_lgl(is_object_list(x));
}
