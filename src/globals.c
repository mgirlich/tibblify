// oriented on https://github.com/r-lib/vctrs/blob/e88a3e28822fa5bf925048e6bd0b10315f7bd9af/src/globals.c

#include "tibblify.h"

struct syms syms;
struct strings strings;
struct chrs chrs;

struct r_dyn_array* globals_shelter = NULL;

// Defines both a string and a length 1 character vector
#define INIT_STRING(ARG)                                \
  strings.ARG = r_str(#ARG);                            \
  r_dyn_list_push_back(globals_shelter, strings.ARG);   \
  chrs.ARG = r_chr(#ARG);                               \
  r_dyn_list_push_back(globals_shelter, chrs.ARG);

void vctrs_init_globals(r_obj* ns) {
  size_t n_strings = sizeof(struct strings) / sizeof(r_obj*);
  size_t n_globals = n_strings;

  globals_shelter = r_new_dyn_vector(R_TYPE_list, n_globals);
  r_preserve(globals_shelter->shelter);

  // Symbols -----------------------------------------------------------
  syms.arg = r_sym("arg");
  syms.dot_arg = r_sym(".arg");
  syms.dot_call = r_sym(".call");
  syms.dot_error_arg = r_sym(".error_arg");
  syms.dot_error_call = r_sym(".error_call");
  syms.haystack_arg = r_sym("haystack_arg");
  syms.needles_arg = r_sym("needles_arg");
  syms.recurse = r_sym("recurse");
  syms.repair_arg = r_sym("repair_arg");
  syms.times_arg = r_sym("times_arg");
  syms.to_arg = r_sym("to_arg");
  syms.value_arg = r_sym("value_arg");
  syms.x_arg = r_sym("x_arg");
  syms.y_arg = r_sym("y_arg");

  // Strings and characters --------------------------------------------
  INIT_STRING(AsIs);
  INIT_STRING(repair);
}
