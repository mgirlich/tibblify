#ifndef TIBBLIFY_UTILS_H
#define TIBBLIFY_UTILS_H

// #include <vector>

#include "collector.h"
#include "tibblify.h"

r_obj* r_list_get_by_name(r_obj* x, const char* nm);

r_obj* apply_transform(r_obj* value, r_obj* fn);

static inline
r_obj* vec_flatten(r_obj* value, r_obj* ptype) {
  r_obj* call = KEEP(r_call3(syms_vec_flatten,
                             value,
                             ptype));
  r_obj* out = r_eval(call, tibblify_ns_env);
  FREE(1);
  return(out);
}

static inline
r_obj* names2(r_obj* x) {
  r_obj* nms = r_names(x);

  if (nms == r_null) {
    r_ssize n = r_length(x);
    nms = KEEP(r_alloc_character(n));
    r_chr_fill(nms, r_strs.empty, n);
  } else {
    KEEP(nms);
  }

  FREE(1);
  return nms;
}

void match_chr(r_obj* needles_sorted,
               r_obj* haystack,
               int* indices,
               const r_ssize n_haystack);

// struct Vector_Args
// {
//   vector_input_form input_form;
//   bool vector_allows_empty_list;
//   r_obj* names_to;
//   r_obj* values_to;
//   r_obj* na;
//   r_obj* elt_transform;
//
//   Vector_Args(vector_input_form input_form_,
//               bool vector_allows_empty_list_,
//               SEXP names_to_,
//               SEXP values_to_,
//               SEXP na_,
//               SEXP elt_transform_)
//     : input_form(input_form_)
//     , vector_allows_empty_list(vector_allows_empty_list_)
//     , names_to(names_to_)
//     , values_to(values_to_)
//     , na(na_)
//     , elt_transform(elt_transform_) { }
// };
//
// struct Field_Args
// {
//   r_obj* default_sexp;
//   r_obj* transform;
//   r_obj* ptype;
//   r_obj* ptype_inner;
//
//   Field_Args(cpp11::sexp default_sexp_ = R_NilValue,
//              cpp11::sexp transform_ = R_NilValue,
//              cpp11::sexp ptype_ = R_NilValue,
//              cpp11::sexp ptype_inner_ = R_NilValue)
//     : default_sexp(default_sexp_)
//     , transform(transform_)
//     , ptype(ptype_)
//     , ptype_inner(ptype_inner_) { }
// };
//
// inline vector_input_form string_to_form_enum(cpp11::r_string input_form_) {
//   if (input_form_ == "vector") {
//     return(vector);
//   } else if (input_form_ == "scalar_list") {
//     return(scalar_list);
//   } else if (input_form_ == "object") {
//     return(object);
//   } else{
//     cpp11::stop("Internal error.");
//   }
// }
//
static inline
r_obj* vector_input_form_to_sexp(enum vector_form input_form) {
  switch (input_form) {
  case VECTOR_FORM_vector: return r_chr("scalar_list");
  case VECTOR_FORM_scalar_list: return r_chr("vector");
  case VECTOR_FORM_object: return r_chr("object");
  }
}
//
// inline
// SEXP set_df_attributes(SEXP list, SEXP col_names, R_xlen_t n_rows) {
//   Rf_setAttrib(list, R_NamesSymbol, col_names);
//   Rf_setAttrib(list, R_ClassSymbol, classes_tibble);
//
//   SEXP row_attr = PROTECT(Rf_allocVector(INTSXP, 2));
//   int* row_attr_data = INTEGER(row_attr);
//   row_attr_data[0] = NA_INTEGER;
//   row_attr_data[1] = -n_rows;
//   Rf_setAttrib(list, R_RowNamesSymbol, row_attr);
//
//   UNPROTECT(1);
//   return list;
// }
//
// inline
// SEXP init_df(R_xlen_t n_rows, SEXP col_names) {
//   int n_cols = Rf_length(col_names);
//   SEXP df = PROTECT(Rf_allocVector(VECSXP, n_cols));
//
//   set_df_attributes(df, col_names, n_rows);
//
//   UNPROTECT(1);
//   return df;
// }
//
// inline
// SEXP set_list_of_attributes(SEXP x, SEXP ptype) {
//   Rf_setAttrib(x, R_ClassSymbol, classes_list_of);
//   Rf_setAttrib(x, Rf_install("ptype"), ptype);
//
//   return x;
// }
//
// static inline
// SEXP r_new_environment(SEXP parent) {
//   SEXP env = Rf_allocSExp(ENVSXP);
//   SET_ENCLOS(env, parent);
//   return env;
// }
//
// inline
// bool vec_is_list(SEXP x) {
//   SEXP call = PROTECT(Rf_lang2(syms_vec_is_list, syms_x));
//
//   SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
//   Rf_defineVar(syms_x, x, mask);
//   SEXP out = PROTECT(Rf_eval(call, mask));
//
//   UNPROTECT(3);
//   return Rf_asLogical(out) == 1;
// }
//
static inline
bool vec_is(SEXP x, SEXP ptype) {
  SEXP call = KEEP(Rf_lang3(syms_vec_is, syms_x, syms_ptype));

  r_obj* mask = KEEP(r_alloc_environment(2, r_envs.global));
  r_env_poke(mask, syms_x, x);
  r_env_poke(mask, syms_ptype, ptype);
  r_obj* out = KEEP(r_eval(call, mask));

  FREE(3);
  return Rf_asLogical(out) == 1;
}
//
// inline
// SEXP my_vec_names2(SEXP x) {
//   SEXP call = PROTECT(Rf_lang2(syms_vec_names2, syms_x));
//
//   SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
//   Rf_defineVar(syms_x, x, mask);
//   SEXP out = PROTECT(Rf_eval(call, mask));
//
//   UNPROTECT(3);
//   return out;
// }
//
// inline
// SEXP vec_slice_impl2(SEXP x, SEXP index) {
//   SEXP row = PROTECT(vec_slice_impl(x, index));
//
//   R_xlen_t n_cols = Rf_length(row);
//   for (R_xlen_t i = 0; i < n_cols; i++) {
//     SEXP col = VECTOR_ELT(row, i);
//     if (TYPEOF(col) == VECSXP && !Rf_inherits(col, "data.frame")) {
//       SET_VECTOR_ELT(row, i, VECTOR_ELT(col, 0));
//     }
//   }
//
//   UNPROTECT(1);
//   return(row);
// }
//
// inline
// std::vector<int> order_chr(SEXP x) {
//   const int n = Rf_length(x);
//   std::vector<int> out;
//   out.reserve(n);
//   R_orderVector1(out.data(), n, x, FALSE, FALSE);
//   return(out);
// }
//
// inline
// std::vector<int> match_chr(SEXP needles_sorted, SEXP haystack) {
//   LOG_DEBUG;
//
//   // CAREFUL: this assumes needles to be sorted!
//   const SEXP* needles_ptr = STRING_PTR_RO(needles_sorted);
//   const SEXP* haystack_ptr = STRING_PTR_RO(haystack);
//
//   auto haystack_ind = order_chr(haystack);
//   const R_xlen_t n_needles = Rf_length(needles_sorted);
//   const R_xlen_t n_haystack = Rf_length(haystack);
//
//   std::vector<int> indices;
//   indices.reserve(n_needles);
//
//   int i = 0;
//   int j = 0;
//   for (i = 0; (i < n_needles) && (j < n_haystack); ) {
//     SEXPREC* hay = haystack_ptr[haystack_ind[j]];
//     LOG_DEBUG << "needle: " << CHAR(*needles_ptr) << " - hay: " << CHAR(hay);
//
//     if (*needles_ptr == hay) {
//       indices[i] = haystack_ind[j];
//       needles_ptr++;
//       i++; j++;
//       continue;
//     }
//
//     const char* needle_char = CHAR(*needles_ptr);
//     const char* hay_char = CHAR(hay);
//     // needle is too small, so go to next needle
//     if (strcmp(needle_char, hay_char) < 0) {
//       LOG_DEBUG << "needle too small";
//       // needle not found in haystack
//       indices[i] = -1;
//       needles_ptr++; i++;
//     } else {
//       LOG_DEBUG << "hay too small";
//       j++;
//     }
//   }
//
//   // mark remaining needles as not found
//   for (; i < n_needles; i++) {
//     indices[i] = -1;
//   }
//
//   return(indices);
// }
//
// inline
// cpp11::writable::strings na_chr(R_xlen_t n) {
//   auto out = cpp11::writable::strings(n);
//   for (int i = 0; i < n; i++) {
//     out[i] = NA_STRING;
//   }
//
//   return(out);
// }

#endif
