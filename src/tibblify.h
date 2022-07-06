#ifndef SLIDER_H
#define SLIDER_H

#define R_NO_REMAP
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

extern SEXP strings_empty;

extern SEXP classes_tibble;
extern SEXP classes_list_of;

extern SEXP tibblify_shared_empty_lgl;
extern SEXP tibblify_shared_empty_int;
extern SEXP tibblify_shared_empty_dbl;
// extern SEXP tibblify_shared_empty_cpl;
extern SEXP tibblify_shared_empty_chr;
// extern SEXP tibblify_shared_empty_raw;
extern SEXP tibblify_shared_empty_list;
// extern SEXP tibblify_shared_empty_date;
// extern SEXP tibblify_shared_empty_uns;

extern SEXP syms_transform;
extern SEXP syms_value;
extern SEXP syms_x;
extern SEXP syms_ptype;

extern SEXP syms_vec_is_list;
extern SEXP syms_vec_is;
extern SEXP syms_vec_names2;
extern SEXP syms_vec_flatten;
extern SEXP syms_vec_init;

#endif
