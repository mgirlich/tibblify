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

// inline vector_input_form string_to_form_enum(cpp11::r_string input_form_) {
//   if (input_form_ == "vector") {
//     return(vector);
//   } else if (input_form_ == "scalar_list") {
//     return(scalar_list);
//   } else if (input_form_ == "object") {
//     return(object);
//   } else{
//     cpp11::stop("Internal error.");
//   }
// }
//
// inline
// SEXP set_df_attributes(SEXP list, SEXP col_names, R_xlen_t n_rows) {
//   Rf_setAttrib(list, R_NamesSymbol, col_names);
//   Rf_setAttrib(list, R_ClassSymbol, classes_tibble);
//
//   SEXP row_attr = PROTECT(Rf_allocVector(INTSXP, 2));
//   int* row_attr_data = INTEGER(row_attr);
//   row_attr_data[0] = NA_INTEGER;
//   row_attr_data[1] = -n_rows;
//   Rf_setAttrib(list, R_RowNamesSymbol, row_attr);
//
//   UNPROTECT(1);
//   return list;
// }
//
// inline
// SEXP init_df(R_xlen_t n_rows, SEXP col_names) {
//   int n_cols = Rf_length(col_names);
//   SEXP df = PROTECT(Rf_allocVector(VECSXP, n_cols));
//
//   set_df_attributes(df, col_names, n_rows);
//
//   UNPROTECT(1);
//   return df;
// }
//
// inline
// SEXP set_list_of_attributes(SEXP x, SEXP ptype) {
//   Rf_setAttrib(x, R_ClassSymbol, classes_list_of);
//   Rf_setAttrib(x, r_sym("ptype"), ptype);
//
//   return x;
// }
//
// static inline
// SEXP r_new_environment(SEXP parent) {
//   SEXP env = Rf_allocSExp(ENVSXP);
//   SET_ENCLOS(env, parent);
//   return env;
// }
//
// inline
// bool vec_is_list(SEXP x) {
//   SEXP call = PROTECT(Rf_lang2(syms_vec_is_list, syms_x));
//
//   SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
//   Rf_defineVar(syms_x, x, mask);
//   SEXP out = PROTECT(Rf_eval(call, mask));
//
//   UNPROTECT(3);
//   return Rf_asLogical(out) == 1;
// }
//
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
//
// inline
// SEXP my_vec_names2(SEXP x) {
//   SEXP call = PROTECT(Rf_lang2(syms_vec_names2, syms_x));
//
//   SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
//   Rf_defineVar(syms_x, x, mask);
//   SEXP out = PROTECT(Rf_eval(call, mask));
//
//   UNPROTECT(3);
//   return out;
// }
//
// inline
// SEXP vec_slice_impl2(SEXP x, SEXP index) {
//   SEXP row = PROTECT(vec_slice_impl(x, index));
//
//   R_xlen_t n_cols = Rf_length(row);
//   for (R_xlen_t i = 0; i < n_cols; i++) {
//     SEXP col = VECTOR_ELT(row, i);
//     if (TYPEOF(col) == VECSXP && !Rf_inherits(col, "data.frame")) {
//       SET_VECTOR_ELT(row, i, VECTOR_ELT(col, 0));
//     }
//   }
//
//   UNPROTECT(1);
//   return(row);
// }
//
// inline
// cpp11::writable::strings na_chr(R_xlen_t n) {
//   auto out = cpp11::writable::strings(n);
//   for (int i = 0; i < n; i++) {
//     out[i] = NA_STRING;
//   }
//
//   return(out);
// }

#endif
