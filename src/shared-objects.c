#include "tibblify.h"

SEXP tibblify_ns_env = NULL;

SEXP strings = NULL;
// SEXP strings_date = NULL;
SEXP strings_list_of = NULL;
SEXP strings_vctr = NULL;
SEXP strings_list = NULL;

// SEXP classes_date = NULL;
SEXP classes_tibble = NULL;
SEXP classes_list_of = NULL;

SEXP strings_object = NULL;
SEXP strings_df = NULL;
SEXP strings_row = NULL;
SEXP strings_empty = NULL;

SEXP syms_ptype = NULL;
SEXP syms_transform = NULL;
SEXP syms_value = NULL;
SEXP syms_x = NULL;

SEXP syms_vec_is_list = NULL;
SEXP syms_vec_is = NULL;
SEXP syms_vec_flatten = NULL;
SEXP syms_vec_names2 = NULL;
SEXP syms_vec_init = NULL;

SEXP r_new_shared_vector(SEXPTYPE type, R_len_t n) {
  SEXP out = Rf_allocVector(type, n);
  R_PreserveObject(out);
  MARK_NOT_MUTABLE(out);
  return out;
}

void tibblify_init_utils(SEXP ns) {
  tibblify_ns_env = ns;

  // Holds the CHARSXP objects because unlike symbols they can be
  // garbage collected
  strings = r_new_shared_vector(STRSXP, 1);

  classes_tibble = r_new_shared_vector(STRSXP, 3);

  r_preserve_global(r_string_types.sub = r_str("sub"));
  r_preserve_global(r_string_types.row = r_str("row"));
  r_preserve_global(r_string_types.df = r_str("df"));
  r_preserve_global(r_string_types.scalar = r_str("scalar"));
  r_preserve_global(r_string_types.vector = r_str("vector"));
  r_preserve_global(r_string_types.variant = r_str("variant"));
  // TODO need unspecified?

  r_preserve_global(r_vector_form.vector = r_str("vector"));
  r_preserve_global(r_vector_form.scalar_list = r_str("scalar_list"));
  r_preserve_global(r_vector_form.object_list = r_str("object"));

  classes_list_of = r_new_shared_vector(STRSXP, 3);
  strings_list_of = Rf_mkChar("vctrs_list_of");
  SET_STRING_ELT(classes_list_of, 0, strings_list_of);
  strings_vctr = Rf_mkChar("vctrs_vctr");
  SET_STRING_ELT(classes_list_of, 1, strings_vctr);
  strings_list = Rf_mkChar("list");
  SET_STRING_ELT(classes_list_of, 2, strings_list);

  r_preserve_global(strings_empty = r_str(""));
  r_preserve_global(strings_object = r_str("object"));
  r_preserve_global(strings_df = r_str("df"));
  r_preserve_global(strings_row = r_str("row"));

  syms_ptype = r_sym("ptype");
  syms_transform = r_sym("transform");
  syms_value = r_sym("value");
  syms_x = r_sym("x");

  SEXP vctrs_package = Rf_findVarInFrame(R_NamespaceRegistry, r_sym("vctrs"));
  syms_vec_is_list = Rf_findFun(r_sym("vec_is_list"), vctrs_package);
  syms_vec_is = Rf_findFun(r_sym("vec_is"), vctrs_package);
  syms_vec_names2 = Rf_findFun(r_sym("vec_names2"), vctrs_package);
  syms_vec_init = Rf_findFun(r_sym("vec_init"), vctrs_package);

  SEXP tibblify_symbol = r_sym("tibblify");
  SEXP tibblify_package = Rf_findVarInFrame(R_NamespaceRegistry, tibblify_symbol);
  syms_vec_flatten = Rf_findFun(r_sym("vec_flatten"), tibblify_package);
}
