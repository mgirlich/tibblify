#include "utils.h"

r_obj* r_list_get_by_name(r_obj* x, const char* nm) {
  r_obj* names = r_names(x);
  const r_ssize n = r_length(names);
  // TODO add checks;

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

  r_ssize i = 0;
  r_ssize j = 0;
  for (i = 0; (i < n_needles) && (j < n_haystack); ) {
    r_obj* hay = v_haystack[haystack_ind[j]];
    if (*v_needles == hay) {
      indices[i] = haystack_ind[j];
      ++v_needles;
      ++i; ++j;
      continue;
    }

    const char* needle_char = r_str_c_string(*v_needles);
    const char* hay_char = r_str_c_string(hay);
    // needle is too small, so go to next needle
    if (strcmp(needle_char, hay_char) < 0) {
      // needle not found in haystack
      indices[i] = -1;
      ++v_needles; ++i;
    } else {
      ++j;
    }
  }

  // mark remaining needles as not found
  for (; i < n_needles; i++) {
    indices[i] = -1;
  }

  return;
}
