#ifndef TIBBLIFY_UTILS_H
#define TIBBLIFY_UTILS_H

// #include <vector>

#include "collector.h"
#include "tibblify.h"

static inline
bool is_data_frame(r_obj* x) {
  return r_inherits(x, "data.frame");
}

r_obj* r_list_get_by_name(r_obj* x, const char* nm);

r_obj* apply_transform(r_obj* value, r_obj* fn);

static inline
r_obj* vec_flatten(r_obj* value, r_obj* ptype) {
  r_obj* call = KEEP(r_call3(syms_vec_flatten,
                             value,
                             ptype));
  r_obj* out = r_eval(call, tibblify_ns_env);
  FREE(1);
  return(out);
}

static inline
r_obj* names2(r_obj* x) {
  r_obj* nms = r_names(x);

  if (nms == r_null) {
    r_ssize n = r_length(x);
    nms = KEEP(r_alloc_character(n));
    r_chr_fill(nms, r_strs.empty, n);
  } else {
    KEEP(nms);
  }

  FREE(1);
  return nms;
}

void match_chr(r_obj* needles_sorted,
               r_obj* haystack,
               int* indices,
               const r_ssize n_haystack);

bool chr_equal(r_obj* x, r_obj* y);

void check_names_unique(r_obj* field_names,
                        const int ind[],
                        const int n_fields,
                        const struct Path* path);

static inline
bool vec_is(SEXP x, SEXP ptype) {
  SEXP call = KEEP(Rf_lang3(syms_vec_is, syms_x, syms_ptype));

  r_obj* mask = KEEP(r_alloc_environment(2, r_envs.global));
  r_env_poke(mask, syms_x, x);
  r_env_poke(mask, syms_ptype, ptype);
  r_obj* out = KEEP(r_eval(call, mask));

  FREE(3);
  return Rf_asLogical(out) == 1;
}

#endif
