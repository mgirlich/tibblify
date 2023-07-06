// oriented on https://github.com/r-lib/vctrs/blob/e88a3e28822fa5bf925048e6bd0b10315f7bd9af/src/utils.h

#include "tibblify-core.h"

// strings.AsIs

inline void never_reached(const char* fn) {
  Rf_error("Internal error in `%s()`: Reached the unreachable.", fn);
}

SEXP strings_tbl = NULL;
SEXP strings_tbl_df = NULL;
SEXP strings_data_frame = NULL;
SEXP strings_date = NULL;
SEXP strings_posixct = NULL;
SEXP strings_posixlt = NULL;
SEXP strings_posixt = NULL;
SEXP strings_factor = NULL;
SEXP strings_ordered = NULL;
SEXP strings_list = NULL;

void vctrs_init_utils(SEXP ns) {
  // vctrs_shared_empty_str = Rf_mkString("");
  // R_PreserveObject(vctrs_shared_empty_str);
  //
  //
  // Holds the CHARSXP objects because unlike symbols they can be
  // garbage collected
  // strings2 = r_new_shared_vector(STRSXP, 25);
  //
  // strings_dots = Rf_mkChar("...");
  // SET_STRING_ELT(strings2, 0, strings_dots);
  //
  // strings_empty = Rf_mkChar("");
  // SET_STRING_ELT(strings2, 1, strings_empty);
  //
  // strings_date = Rf_mkChar("Date");
  // SET_STRING_ELT(strings2, 2, strings_date);
  //
  // strings_posixct = Rf_mkChar("POSIXct");
  // SET_STRING_ELT(strings2, 3, strings_posixct);
  //
  // strings_posixlt = Rf_mkChar("POSIXlt");
  // SET_STRING_ELT(strings2, 4, strings_posixlt);
  //
  // strings_posixt = Rf_mkChar("POSIXt");
  // SET_STRING_ELT(strings2, 5, strings_posixt);
  //
  // strings_key = Rf_mkChar("key");
  // SET_STRING_ELT(strings2, 11, strings_key);
  //
  // strings_loc = Rf_mkChar("loc");
  // SET_STRING_ELT(strings2, 12, strings_loc);
  //
  // strings_val = Rf_mkChar("val");
  // SET_STRING_ELT(strings2, 13, strings_val);
  //
  // strings_group = Rf_mkChar("group");
  // SET_STRING_ELT(strings2, 14, strings_group);
  //
  // strings_length = Rf_mkChar("length");
  // SET_STRING_ELT(strings2, 15, strings_length);
  //
  // strings_factor = Rf_mkChar("factor");
  // SET_STRING_ELT(strings2, 16, strings_factor);
  //
  // strings_ordered = Rf_mkChar("ordered");
  // SET_STRING_ELT(strings2, 17, strings_ordered);
  //
  // strings_list = Rf_mkChar("list");
  // SET_STRING_ELT(strings2, 18, strings_list);
  //
  // strings_vctrs_vctr = Rf_mkChar("vctrs_vctr");
  // SET_STRING_ELT(strings2, 19, strings_vctrs_vctr);
  //
  // strings_times = Rf_mkChar("times");
  // SET_STRING_ELT(strings2, 20, strings_times);


  // classes_tibble = r_new_shared_vector(STRSXP, 3);

  strings_tbl_df = Rf_mkChar("tbl_df");
  // SET_STRING_ELT(classes_tibble, 0, strings_tbl_df);

  strings_tbl = Rf_mkChar("tbl");
  // SET_STRING_ELT(classes_tibble, 1, strings_tbl);
  // SET_STRING_ELT(classes_tibble, 2, strings_data_frame);


  // vctrs_shared_empty_date = r_new_shared_vector(REALSXP, 0);
  // Rf_setAttrib(vctrs_shared_empty_date, R_ClassSymbol, classes_date);

  // vctrs_shared_na_lgl = r_new_shared_vector(LGLSXP, 1);
  // LOGICAL(vctrs_shared_na_lgl)[0] = NA_LOGICAL;

  // vctrs_shared_na_list = r_new_shared_vector(VECSXP, 1);
  // SET_VECTOR_ELT(vctrs_shared_na_list, 0, R_NilValue);

  // vctrs_shared_zero_int = r_new_shared_vector(INTSXP, 1);
  // INTEGER(vctrs_shared_zero_int)[0] = 0;

  // syms_*
  // syms_i = Rf_install("i");

  // fns_*
  // fns_bracket = Rf_findVar(syms_bracket, R_BaseEnv);
}
