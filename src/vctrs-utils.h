// oriented on https://github.com/r-lib/vctrs/blob/e88a3e28822fa5bf925048e6bd0b10315f7bd9af/src/utils.h

#include "tibblify-core.h"

void never_reached(const char* fn) __attribute__((noreturn));

extern SEXP strings_tbl;
extern SEXP strings_tbl_df;
extern SEXP strings_data_frame;
extern SEXP strings_date;
extern SEXP strings_posixct;
extern SEXP strings_posixlt;
extern SEXP strings_posixt;
extern SEXP strings_factor;
extern SEXP strings_ordered;
extern SEXP strings_list;
