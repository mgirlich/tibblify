#ifndef TIBBLIFY_VCTRS_PRIVATE_H
#define TIBBLIFY_VCTRS_PRIVATE_H

#include "tibblify.h"

// Experimental non-public vctrs functions
extern SEXP (*vec_cast)(SEXP, SEXP);
extern SEXP (*vec_chop)(SEXP, SEXP);
extern SEXP (*vec_slice_impl)(SEXP, SEXP);
extern SEXP (*vec_names)(SEXP);
extern SEXP (*vec_set_names)(SEXP, SEXP);
extern SEXP (*compact_seq)(R_len_t, R_len_t, bool);
extern SEXP (*init_compact_seq)(int*, R_len_t, R_len_t, bool);

#endif
