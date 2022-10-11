#include "utils.h"

r_obj* r_list_get_by_name(r_obj* x, const char* nm) {
  r_obj* names = r_names(x);
  const r_ssize n = r_length(names);
  // TODO add checks;

  r_obj* const * v_x = r_list_cbegin(x);

  for (r_ssize i = 0; i < n; ++i) {
    if (strcmp(r_chr_get_c_string(names, i), nm) == 0) {
      return v_x[i];
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
