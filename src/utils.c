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
