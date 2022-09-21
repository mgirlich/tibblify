#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

// Defined below
SEXP tibblify_initialize(SEXP);

// tibblify-vctrs-private.c
void tibblify_initialize_vctrs_private();

// tibblify-vctrs-public.c
void tibblify_initialize_vctrs_public();

// utils.c
void tibblify_init_utils(SEXP);

// utils.c
SEXP r_init_library(SEXP);

SEXP tibblify_initialize(SEXP ns) {
  r_init_library(ns);

  tibblify_initialize_vctrs_private();
  tibblify_initialize_vctrs_public();
  tibblify_init_utils(ns);
  return R_NilValue;
}
