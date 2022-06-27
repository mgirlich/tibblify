#include <cpp11.hpp>
#include "tibblify.h"

enum vector_input_form {vector, scalar_list, object};

inline cpp11::sexp vector_input_form_to_sexp(vector_input_form input_form) {
  cpp11::r_string input_form_string;
  switch (input_form) {
  case scalar_list: {input_form_string = "scalar_list";} break;
  case vector: {input_form_string = "vector";} break;
  case object: {input_form_string = "object";} break;
  }

  return(cpp11::as_sexp(input_form_string));
}

inline
SEXP set_df_attributes(SEXP list, R_xlen_t n_rows) {
  Rf_setAttrib(list, R_ClassSymbol, classes_tibble);

  SEXP row_attr = PROTECT(Rf_allocVector(INTSXP, 2));
  int* row_attr_data = INTEGER(row_attr);
  row_attr_data[0] = NA_INTEGER;
  row_attr_data[1] = -n_rows;
  Rf_setAttrib(list, R_RowNamesSymbol, row_attr);

  UNPROTECT(1);
  return list;
}

inline
SEXP init_df(R_xlen_t n_rows, SEXP col_names) {
  int n_cols = Rf_length(col_names);
  SEXP df = PROTECT(Rf_allocVector(VECSXP, n_cols));
  Rf_setAttrib(df, R_NamesSymbol, col_names);

  set_df_attributes(df, n_rows);

  UNPROTECT(1);
  return df;
}

inline
SEXP init_list_of(R_xlen_t& length, SEXP ptype) {
  SEXP out = PROTECT(Rf_allocVector(VECSXP, length));
  Rf_setAttrib(out, R_ClassSymbol, classes_list_of);
  Rf_setAttrib(out, Rf_install("ptype"), ptype);

  UNPROTECT(1);
  return out;
}

static inline
SEXP r_new_environment(SEXP parent) {
  SEXP env = Rf_allocSExp(ENVSXP);
  SET_ENCLOS(env, parent);
  return env;
}

inline
bool vec_is_list(SEXP x) {
  SEXP call = PROTECT(Rf_lang2(syms_vec_is_list, syms_x));

  SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
  Rf_defineVar(syms_x, x, mask);
  SEXP out = PROTECT(Rf_eval(call, mask));

  UNPROTECT(3);
  return Rf_asLogical(out) == 1;
}

inline
bool vec_is(SEXP x, SEXP ptype) {
  SEXP call = PROTECT(Rf_lang3(syms_vec_is, syms_x, syms_ptype));

  SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
  Rf_defineVar(syms_x, x, mask);
  Rf_defineVar(syms_ptype, ptype, mask);
  SEXP out = PROTECT(Rf_eval(call, mask));

  UNPROTECT(3);
  return Rf_asLogical(out) == 1;
}

inline
SEXP my_vec_names2(SEXP x) {
  SEXP call = PROTECT(Rf_lang2(syms_vec_names2, syms_x));

  SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
  Rf_defineVar(syms_x, x, mask);
  SEXP out = PROTECT(Rf_eval(call, mask));

  UNPROTECT(3);
  return out;
}

inline
SEXP vec_slice_impl2(SEXP x, SEXP index) {
  SEXP row = vec_slice_impl(x, index);

  R_xlen_t n_cols = Rf_length(row);
  for (R_xlen_t i = 0; i < n_cols; i++) {
    SEXP col = VECTOR_ELT(row, i);
    if (TYPEOF(col) == VECSXP && !Rf_inherits(col, "data.frame")) {
      SET_VECTOR_ELT(row, i, VECTOR_ELT(col, 0));
    }
  }

  return(row);
}
