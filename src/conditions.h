#include "tibblify.h"
#include "utils.h"
#include "Path.h"

inline void stop_scalar(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_scalar"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_required(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_required"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_duplicate_name(const Path& path, SEXPREC* field_nm) {
  SEXP call = PROTECT(Rf_lang3(Rf_install("stop_duplicate_name"),
                               PROTECT(path.data()),
                               cpp11::as_sexp(cpp11::r_string(field_nm))));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_empty_name(const Path& path, const int& index) {
  SEXP call = PROTECT(Rf_lang3(Rf_install("stop_empty_name"),
                               PROTECT(path.data()),
                               cpp11::as_sexp(index)));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_names_is_null(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_names_is_null"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_object_vector_names_is_null(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_object_vector_names_is_null"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_vector_non_list_element(const Path& path, vector_input_form input_form) {
  cpp11::sexp input_form_string = vector_input_form_to_sexp(input_form);
  SEXP call = PROTECT(Rf_lang3(Rf_install("stop_vector_non_list_element"),
                               PROTECT(path.data()),
                               input_form_string));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_vector_wrong_size_element(const Path& path, vector_input_form input_form) {
  SEXP call = PROTECT(Rf_lang3(Rf_install("stop_vector_wrong_size_element"),
                               PROTECT(path.data()),
                               vector_input_form_to_sexp(input_form)));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_colmajor_wrong_size_element(const Path& path, R_xlen_t size_exp, R_xlen_t size_act) {
  SEXP call = PROTECT(Rf_lang4(Rf_install("stop_colmajor_wrong_size_element"),
                               PROTECT(path.data()),
                               cpp11::as_sexp(size_exp),
                               // cpp11::integers{size_exp},
                               cpp11::as_sexp(size_act)));
  Rf_eval(call, tibblify_ns_env);
}

inline void check_colmajor_size(SEXP value, R_xlen_t n_rows, const Path& path) {
  R_len_t size = short_vec_size(value);
  if (n_rows != size) {
    stop_colmajor_wrong_size_element(path, n_rows, size);
  }
}

inline void stop_colmajor_non_list_element(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_colmajor_non_list_element"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}
