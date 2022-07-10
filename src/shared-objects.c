#include "tibblify.h"

SEXP tibblify_ns_env = NULL;

SEXP strings = NULL;
SEXP strings_empty = NULL;
SEXP strings_tbl = NULL;
SEXP strings_tbl_df = NULL;
SEXP strings_data_frame = NULL;
// SEXP strings_date = NULL;
SEXP strings_list_of = NULL;
SEXP strings_vctr = NULL;
SEXP strings_list = NULL;

SEXP tibblify_shared_empty_lgl = NULL;
SEXP tibblify_shared_empty_int = NULL;
SEXP tibblify_shared_empty_dbl = NULL;
// SEXP tibblify_shared_empty_cpl = NULL;
SEXP tibblify_shared_empty_chr = NULL;
// SEXP tibblify_shared_empty_raw = NULL;
SEXP tibblify_shared_empty_list = NULL;
SEXP tibblify_shared_empty_named_list = NULL;
// SEXP tibblify_shared_empty_date = NULL;
// SEXP tibblify_shared_empty_uns = NULL;

// SEXP classes_date = NULL;
SEXP classes_tibble = NULL;
SEXP classes_list_of = NULL;

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

  // strings_date = Rf_mkChar("Date");
  // SET_STRING_ELT(strings, 0, strings_date);
  //
  // classes_date = r_new_shared_vector(STRSXP, 1);
  // SET_STRING_ELT(classes_date, 0, strings_date);

  classes_tibble = r_new_shared_vector(STRSXP, 3);

  strings_empty = Rf_mkChar("");
  SET_STRING_ELT(strings, 0, strings_empty);

  strings_tbl_df = Rf_mkChar("tbl_df");
  SET_STRING_ELT(classes_tibble, 0, strings_tbl_df);

  strings_tbl = Rf_mkChar("tbl");
  SET_STRING_ELT(classes_tibble, 1, strings_tbl);
  strings_data_frame = Rf_mkChar("data.frame");
  SET_STRING_ELT(classes_tibble, 2, strings_data_frame);

  classes_list_of = r_new_shared_vector(STRSXP, 3);
  strings_list_of = Rf_mkChar("vctrs_list_of");
  SET_STRING_ELT(classes_list_of, 0, strings_list_of);
  strings_vctr = Rf_mkChar("vctrs_vctr");
  SET_STRING_ELT(classes_list_of, 1, strings_vctr);
  strings_list = Rf_mkChar("list");
  SET_STRING_ELT(classes_list_of, 2, strings_list);

  tibblify_shared_empty_lgl = r_new_shared_vector(LGLSXP, 0);
  tibblify_shared_empty_int = r_new_shared_vector(INTSXP, 0);
  tibblify_shared_empty_dbl = r_new_shared_vector(REALSXP, 0);
  // tibblify_shared_empty_cpl = r_new_shared_vector(CPLXSXP, 0);
  tibblify_shared_empty_chr = r_new_shared_vector(STRSXP, 0);
  // tibblify_shared_empty_raw = r_new_shared_vector(RAWSXP, 0);
  tibblify_shared_empty_list = r_new_shared_vector(VECSXP, 0);
  tibblify_shared_empty_named_list = r_new_shared_vector(VECSXP, 0);
  Rf_setAttrib(tibblify_shared_empty_named_list, R_NamesSymbol, tibblify_shared_empty_chr);
  // tibblify_shared_empty_date = r_new_shared_vector(REALSXP, 0);
  // Rf_setAttrib(tibblify_shared_empty_date, R_ClassSymbol, classes_date);
  // tibblify_shared_empty_uns = r_new_shared_vector(LGLSXP, 0);

  syms_ptype = Rf_install("ptype");
  syms_transform = Rf_install("transform");
  syms_value = Rf_install("value");
  syms_x = Rf_install("x");

  SEXP vctrs_package = Rf_findVarInFrame(R_NamespaceRegistry, Rf_install("vctrs"));
  syms_vec_is_list = Rf_findFun(Rf_install("vec_is_list"), vctrs_package);
  syms_vec_is = Rf_findFun(Rf_install("vec_is"), vctrs_package);
  syms_vec_names2 = Rf_findFun(Rf_install("vec_names2"), vctrs_package);
  syms_vec_init = Rf_findFun(Rf_install("vec_init"), vctrs_package);

  SEXP tibblify_symbol = Rf_install("tibblify");
  SEXP tibblify_package = Rf_findVarInFrame(R_NamespaceRegistry, tibblify_symbol);
  syms_vec_flatten = Rf_findFun(Rf_install("vec_flatten"), tibblify_package);
}
