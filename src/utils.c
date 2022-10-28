#include "utils.h"
#include "conditions.h"

r_obj* r_list_get_by_name(r_obj* x, const char* nm) {
  r_obj* names = r_names(x);
  const r_ssize n = r_length(names);

  for (r_ssize i = 0; i < n; ++i) {
    if (strcmp(r_chr_get_c_string(names, i), nm) == 0) {
      return r_list_get(x, i);
    }
  }

  r_stop_internal("Field `%s` not found", nm);
  return r_null;
}

r_obj* apply_transform(r_obj* value, r_obj* fn) {
  // from https://github.com/r-lib/vctrs/blob/9b65e090da2a0f749c433c698a15d4e259422542/src/names.c#L83
  r_obj* call = KEEP(r_call2(syms_transform, syms_value));

  r_obj* mask = KEEP(r_alloc_environment(2, R_GlobalEnv));
  r_env_poke(mask, syms_transform, fn);
  r_env_poke(mask, syms_value, value);
  r_obj* out = KEEP(r_eval(call, mask));

  FREE(3);
  return out;
}

void match_chr(r_obj* needles_sorted,
               r_obj* haystack,
               int* indices,
               const r_ssize n_haystack) {
  // CAREFUL: this assumes needles to be sorted!
  r_obj* const * v_needles = r_chr_cbegin(needles_sorted);
  r_obj* const * v_haystack = r_chr_cbegin(haystack);

  const r_ssize n_needles = r_length(needles_sorted);

  int haystack_ind[n_haystack];
  R_orderVector1(haystack_ind, n_haystack, haystack, FALSE, FALSE);

  r_ssize i_needle = 0;
  r_ssize i_hay = 0;
  for (i_needle = 0; (i_needle < n_needles) && (i_hay < n_haystack); ) {
    r_obj* hay = v_haystack[haystack_ind[i_hay]];
    if (*v_needles == hay) {
      indices[i_needle] = haystack_ind[i_hay];
      ++v_needles;
      ++i_needle; ++i_hay;
      continue;
    }

    const char* needle_char = r_str_c_string(*v_needles);
    const char* hay_char = r_str_c_string(hay);
    // needle is too small, so go to next needle
    if (strcmp(needle_char, hay_char) < 0) {
      // needle not found in haystack
      indices[i_needle] = -1;
      ++v_needles; ++i_needle;
    } else {
      ++i_hay;
    }
  }

  // mark remaining needles as not found
  for (; i_needle < n_needles; ++i_needle) {
    indices[i_needle] = -1;
  }

  return;
}

bool chr_equal(r_obj* x, r_obj* y) {
  int n_x = r_length(x);
  int n_y = r_length(y);
  if (n_x != n_y) {
    return false;
  }

  r_obj* const * v_x = r_chr_cbegin(x);
  r_obj* const * v_y = r_chr_cbegin(y);

  for (int i = 0; i < n_x; ++i, ++v_x, ++v_y) {
    if (*v_x != *v_y) {
      return false;
    }
  }

  return true;
}

void check_names_unique(r_obj* field_names,
                        const int ind[],
                        const int n_fields,
                        const struct Path* path) {
  if (n_fields == 0) return;

  r_obj* const * v_field_names = r_chr_cbegin(field_names);
  r_obj* field_nm = v_field_names[ind[0]];
  if (field_nm == r_globals.na_str || field_nm == strings_empty) {
    stop_empty_name(path->data, ind[0]);
  }

  for (int field_index = 1; field_index < n_fields; ++field_index) {
    r_obj* field_nm_prev = field_nm;
    field_nm = v_field_names[ind[field_index]];
    if (field_nm == field_nm_prev) stop_duplicate_name(path->data, field_nm);

    if (field_nm == r_globals.na_str || field_nm == strings_empty) {
      stop_empty_name(path->data, ind[field_index]);
    }
  }
}
