#include "tibblify.h"
#include "utils.h"
// #include "Path.h"

static inline
void stop_scalar(r_ssize size_act, r_obj* path) {
  r_obj* call = KEEP(r_call3(Rf_install("stop_scalar"),
                             path,
                             r_int(size_act)));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_required(r_obj* path) {
  r_obj* call = KEEP(r_call2(Rf_install("stop_required"),
                             path));
  r_eval(call, tibblify_ns_env);
}

// inline void stop_duplicate_name(const Path& path, SEXPREC* field_nm) {
//   SEXP call = PROTECT(r_call3(Rf_install("stop_duplicate_name"),
//                                PROTECT(path.data()),
//                                cpp11::as_sexp(cpp11::r_string(field_nm))));
//   r_eval(call, tibblify_ns_env);
// }
//
// inline void stop_empty_name(const Path& path, const int& index) {
//   SEXP call = PROTECT(r_call3(Rf_install("stop_empty_name"),
//                                PROTECT(path.data()),
//                                r_int(index)));
//   r_eval(call, tibblify_ns_env);
// }

// inline void stop_names_is_null(const Path& path) {
static inline
void stop_names_is_null(r_obj* path) {
  r_obj* call = KEEP(r_call2(Rf_install("stop_names_is_null"),
                             path));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_object_vector_names_is_null(r_obj* path) {
  SEXP call = KEEP(r_call2(Rf_install("stop_object_vector_names_is_null"),
                               path));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_vector_non_list_element(r_obj* path, enum vector_form input_form, r_obj* x) {
  r_obj* input_form_string = KEEP(vector_input_form_to_sexp(input_form));
  r_obj* call = KEEP(r_call4(Rf_install("stop_vector_non_list_element"),
                             path,
                             input_form_string,
                             x));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_vector_wrong_size_element(r_obj* path, enum vector_form input_form, r_obj* x) {
  r_obj* call = KEEP(r_call4(Rf_install("stop_vector_wrong_size_element"),
                             path,
                             vector_input_form_to_sexp(input_form),
                             x));
  r_eval(call, tibblify_ns_env);
}

// inline void stop_colmajor_wrong_size_element(const Path& path, R_xlen_t size_exp, R_xlen_t size_act) {
//   SEXP call = PROTECT(r_call4(Rf_install("stop_colmajor_wrong_size_element"),
//                                PROTECT(path.data()),
//                                cpp11::as_sexp(size_exp),
//                                // cpp11::integers{size_exp},
//                                cpp11::as_sexp(size_act)));
//   r_eval(call, tibblify_ns_env);
// }
//
// inline void check_colmajor_size(SEXP value, R_xlen_t n_rows, const Path& path) {
//   R_len_t size = short_vec_size(value);
//   if (n_rows != size) {
//     stop_colmajor_wrong_size_element(path, n_rows, size);
//   }
// }
//
// inline void stop_colmajor_non_list_element(const Path& path, SEXP x) {
//   SEXP call = PROTECT(r_call3(Rf_install("stop_colmajor_non_list_element"),
//                                PROTECT(path.data()),
//                                x));
//   r_eval(call, tibblify_ns_env);
// }
