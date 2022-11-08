#include "tibblify.h"
#include "utils.h"
#include "Path.h"

static inline
void stop_scalar(r_ssize size_act, r_obj* path) {
  r_obj* call = KEEP(r_call3(r_sym("stop_scalar"),
                             path,
                             KEEP(r_int(size_act))));
  r_eval(call, tibblify_ns_env);
  FREE(2);
}

static inline
void stop_required(r_obj* path) {
  r_obj* call = KEEP(r_call2(r_sym("stop_required"),
                             path));
  r_eval(call, tibblify_ns_env);
  FREE(1);
}

static inline
void stop_duplicate_name(r_obj* path, r_obj* field_nm_str) {
  r_obj* field_nm_chr = KEEP(r_alloc_character(1));
  r_chr_poke(field_nm_chr, 0, field_nm_str);

  r_obj* call = KEEP(r_call3(r_sym("stop_duplicate_name"),
                             path,
                             field_nm_chr));
  r_eval(call, tibblify_ns_env);
  FREE(2);
}

static inline
void stop_empty_name(r_obj* path, const int index) {
  r_obj* call = KEEP(r_call3(r_sym("stop_empty_name"),
                             path,
                             KEEP(r_int(index))));
  r_eval(call, tibblify_ns_env);
  FREE(2);
}

static inline
void stop_names_is_null(r_obj* path) {
  r_obj* call = KEEP(r_call2(r_sym("stop_names_is_null"),
                             path));
  r_eval(call, tibblify_ns_env);
  FREE(1);
}

static inline
r_obj* check_names_not_null(r_obj* x, struct Path* v_path) {
  r_obj* field_names = r_names(x);
  if (field_names == r_null) {
    stop_names_is_null(v_path->data);
  }

  return field_names;
}

static inline
void stop_object_vector_names_is_null(r_obj* path) {
  SEXP call = KEEP(r_call2(r_sym("stop_object_vector_names_is_null"),
                               path));
  r_eval(call, tibblify_ns_env);
  FREE(1);
}

static inline
void stop_vector_non_list_element(r_obj* path, enum vector_form input_form, r_obj* x) {
  r_obj* input_form_string = KEEP(vector_input_form_to_sexp(input_form));
  r_obj* call = KEEP(r_call4(r_sym("stop_vector_non_list_element"),
                             path,
                             input_form_string,
                             x));
  r_eval(call, tibblify_ns_env);
  FREE(2);
}

static inline
void stop_vector_wrong_size_element(r_obj* path, enum vector_form input_form, r_obj* x) {
  r_obj* call = KEEP(r_call4(r_sym("stop_vector_wrong_size_element"),
                             path,
                             KEEP(vector_input_form_to_sexp(input_form)),
                             x));
  r_eval(call, tibblify_ns_env);
  FREE(2);
}

static inline
void stop_colmajor_null(r_obj* path) {
  r_obj* call = KEEP(r_call2(r_sym("stop_colmajor_null"),
                             path));
  r_eval(call, tibblify_ns_env);
  FREE(1);
}

static inline
void stop_colmajor_wrong_size_element(r_obj* path, r_ssize size_act, r_obj* nrow_path, r_ssize size_exp) {
  r_obj* call = KEEP(r_call5(r_sym("stop_colmajor_wrong_size_element"),
                             path,
                             KEEP(r_int(size_act)),
                             nrow_path,
                             KEEP(r_int(size_exp))));
  r_eval(call, tibblify_ns_env);
  FREE(3);
}

static inline
void check_colmajor_size(r_ssize n_value, r_ssize* n_rows, struct Path* path, struct Path* nrow_path) {
  if (*n_rows == -1) {
    *n_rows = n_value;

    r_obj* depth = KEEP(r_int(*path->depth));
    r_list_poke(nrow_path->data, 0, depth);
    nrow_path->depth = r_int_begin(depth);

    nrow_path->path_elts = KEEP(r_clone(path->path_elts));
    r_list_poke(nrow_path->data, 1, nrow_path->path_elts);

    FREE(2);
    return;
  }

  if (*n_rows != n_value) {
    stop_colmajor_wrong_size_element(path->data, n_value, nrow_path->data, *n_rows);
  }
}

static inline
void stop_required_colmajor(r_obj* path) {
  r_obj* call = KEEP(r_call2(r_sym("stop_required_colmajor"),
                             path));
  r_eval(call, tibblify_ns_env);
  FREE(1);
}

static inline
void stop_non_list_element(r_obj* path, r_obj* x) {
  r_obj* call = KEEP(r_call3(r_sym("stop_non_list_element"),
                             path,
                             x));
  r_eval(call, tibblify_ns_env);
  FREE(1);
}

static inline
void check_list(r_obj* x, struct Path* v_path) {
  if (r_typeof(x) != R_TYPE_list) {
    stop_non_list_element(v_path->data, x);
  }
}
