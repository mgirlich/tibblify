#include "tibblify.h"
#include "utils.h"
// #include "Path.h"

static inline
void stop_scalar(r_ssize size_act, r_obj* path) {
  r_obj* call = KEEP(r_call3(r_sym("stop_scalar"),
                             path,
                             r_int(size_act)));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_required(r_obj* path) {
  r_obj* call = KEEP(r_call2(r_sym("stop_required"),
                             path));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_duplicate_name(r_obj* path, r_obj* field_nm_str) {
  r_obj* field_nm_chr = KEEP(r_alloc_character(1));
  r_chr_poke(field_nm_chr, 0, field_nm_str);

  r_obj* call = KEEP(r_call3(r_sym("stop_duplicate_name"),
                             path,
                             field_nm_chr));
  FREE(1);
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_empty_name(r_obj* path, const int index) {
  r_obj* call = KEEP(r_call3(r_sym("stop_empty_name"),
                             path,
                             r_int(index)));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_names_is_null(r_obj* path) {
  r_obj* call = KEEP(r_call2(r_sym("stop_names_is_null"),
                             path));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_object_vector_names_is_null(r_obj* path) {
  SEXP call = KEEP(r_call2(r_sym("stop_object_vector_names_is_null"),
                               path));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_vector_non_list_element(r_obj* path, enum vector_form input_form, r_obj* x) {
  r_obj* input_form_string = KEEP(vector_input_form_to_sexp(input_form));
  r_obj* call = KEEP(r_call4(r_sym("stop_vector_non_list_element"),
                             path,
                             input_form_string,
                             x));
  r_eval(call, tibblify_ns_env);
}

static inline
void stop_vector_wrong_size_element(r_obj* path, enum vector_form input_form, r_obj* x) {
  r_obj* call = KEEP(r_call4(r_sym("stop_vector_wrong_size_element"),
                             path,
                             vector_input_form_to_sexp(input_form),
                             x));
  r_eval(call, tibblify_ns_env);
}

// inline void stop_colmajor_wrong_size_element(const Path& path, R_xlen_t size_exp, R_xlen_t size_act) {
//   SEXP call = PROTECT(r_call4(r_sym("stop_colmajor_wrong_size_element"),
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
//   SEXP call = PROTECT(r_call3(r_sym("stop_colmajor_non_list_element"),
//                                PROTECT(path.data()),
//                                x));
//   r_eval(call, tibblify_ns_env);
// }
