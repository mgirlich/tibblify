#ifndef TIBBLIFY_H
#define TIBBLIFY_H

#define R_NO_REMAP
#include <rlang.h>
#include <R.h>
#include <Rversion.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <stdbool.h>
#include "tibblify-vctrs.h"

struct Col_Spec;
struct Parse_Spec;

#define VECTOR_PTR_RO(x) ((const SEXP*) DATAPTR_RO(x))

extern SEXP tibblify_ns_env;

extern SEXP classes_tibble;
extern SEXP classes_list_of;

extern SEXP syms_transform;
extern SEXP syms_value;
extern SEXP syms_x;
extern SEXP syms_ptype;

extern SEXP syms_vec_is_list;
extern SEXP syms_vec_is;
extern SEXP syms_vec_names2;
extern SEXP syms_vec_flatten;
extern SEXP syms_vec_init;

struct r_string_types_struct {
  r_obj* sub;
  r_obj* row;
  r_obj* df;
  r_obj* scalar;
  r_obj* vector;
  r_obj* unspecified;
  r_obj* variant;
};

extern struct r_string_types_struct r_string_types;

struct r_vector_form_struct {
  r_obj* vector;
  r_obj* scalar_list;
  r_obj* object_list;
};
extern struct r_vector_form_struct r_vector_form;

#endif
