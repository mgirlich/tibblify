#include "utils.h"
#include "conditions.h"

SEXP tibblify_ns_env = NULL;

SEXP classes_list_of = NULL;

SEXP strings_object = NULL;
SEXP strings_df = NULL;
SEXP strings_row = NULL;
SEXP strings_empty = NULL;

SEXP syms_ptype = NULL;
SEXP syms_transform = NULL;
SEXP syms_value = NULL;
SEXP syms_x = NULL;

SEXP syms_vec_is = NULL;
SEXP syms_vec_flatten = NULL;

// -----------------------------------------------------------------------------

r_obj* r_list_get_by_name(r_obj* x, const char* nm) {
  r_obj* names = r_names(x);
  const r_ssize n = r_length(names);

  for (r_ssize i = 0; i < n; ++i) {
    if (strcmp(r_chr_get_c_string(names, i), nm) == 0) {
      return r_list_get(x, i);
    }
  }

  r_stop_internal("Field `%s` not found", nm);
  return r_null;
}

r_obj* apply_transform(r_obj* value, r_obj* fn) {
  // from https://github.com/r-lib/vctrs/blob/9b65e090da2a0f749c433c698a15d4e259422542/src/names.c#L83
  r_obj* call = KEEP(r_call2(syms_transform, syms_value));

  r_obj* mask = KEEP(r_alloc_environment(2, R_GlobalEnv));
  r_env_poke(mask, syms_transform, fn);
  r_env_poke(mask, syms_value, value);
  r_obj* out = KEEP(r_eval(call, mask));

  FREE(3);
  return out;
}

void match_chr(r_obj* needles_sorted,
               r_obj* haystack,
               int* indices,
               const r_ssize n_haystack) {
  // CAREFUL: this assumes needles to be sorted!
  r_obj* const * v_needles = r_chr_cbegin(needles_sorted);
  r_obj* const * v_haystack = r_chr_cbegin(haystack);

  const r_ssize n_needles = r_length(needles_sorted);

  int haystack_ind[n_haystack];
  R_orderVector1(haystack_ind, n_haystack, haystack, FALSE, FALSE);

  r_ssize i_needle = 0;
  r_ssize i_hay = 0;
  for (i_needle = 0; (i_needle < n_needles) && (i_hay < n_haystack); ) {
    r_obj* hay = v_haystack[haystack_ind[i_hay]];
    if (*v_needles == hay) {
      indices[i_needle] = haystack_ind[i_hay];
      ++v_needles;
      ++i_needle; ++i_hay;
      continue;
    }

    const char* needle_char = r_str_c_string(*v_needles);
    const char* hay_char = r_str_c_string(hay);
    // needle is too small, so go to next needle
    if (strcmp(needle_char, hay_char) < 0) {
      // needle not found in haystack
      indices[i_needle] = -1;
      ++v_needles; ++i_needle;
    } else {
      ++i_hay;
    }
  }

  // mark remaining needles as not found
  for (; i_needle < n_needles; ++i_needle) {
    indices[i_needle] = -1;
  }

  return;
}

bool chr_equal(r_obj* x, r_obj* y) {
  int n_x = r_length(x);
  int n_y = r_length(y);
  if (n_x != n_y) {
    return false;
  }

  r_obj* const * v_x = r_chr_cbegin(x);
  r_obj* const * v_y = r_chr_cbegin(y);

  for (int i = 0; i < n_x; ++i, ++v_x, ++v_y) {
    if (*v_x != *v_y) {
      return false;
    }
  }

  return true;
}

void check_names_unique(r_obj* field_names,
                        const int ind[],
                        const int n_fields,
                        const struct Path* path) {
  if (n_fields == 0) return;

  r_obj* const * v_field_names = r_chr_cbegin(field_names);
  r_obj* field_nm = v_field_names[ind[0]];
  if (field_nm == r_globals.na_str || field_nm == strings_empty) {
    stop_empty_name(path->data, ind[0]);
  }

  for (int field_index = 1; field_index < n_fields; ++field_index) {
    r_obj* field_nm_prev = field_nm;
    field_nm = v_field_names[ind[field_index]];
    if (field_nm == field_nm_prev) stop_duplicate_name(path->data, field_nm);

    if (field_nm == r_globals.na_str || field_nm == strings_empty) {
      stop_empty_name(path->data, ind[field_index]);
    }
  }
}

// -----------------------------------------------------------------------------

r_obj* r_new_shared_vector(SEXPTYPE type, R_len_t n) {
  r_obj* out = Rf_allocVector(type, n);
  R_PreserveObject(out);
  MARK_NOT_MUTABLE(out);
  return out;
}

// [[register()]]
void tibblify_init_utils(SEXP ns) {
  tibblify_ns_env = ns;

  r_preserve_global(r_string_input_form.rowmajor = r_str("rowmajor"));
  r_preserve_global(r_string_input_form.colmajor = r_str("colmajor"));

  r_preserve_global(r_string_types.sub = r_str("sub"));
  r_preserve_global(r_string_types.row = r_str("row"));
  r_preserve_global(r_string_types.df = r_str("df"));
  r_preserve_global(r_string_types.scalar = r_str("scalar"));
  r_preserve_global(r_string_types.vector = r_str("vector"));
  r_preserve_global(r_string_types.variant = r_str("variant"));

  r_preserve_global(r_vector_form.vector = r_str("vector"));
  r_preserve_global(r_vector_form.scalar_list = r_str("scalar_list"));
  r_preserve_global(r_vector_form.object_list = r_str("object"));

  classes_list_of = r_new_shared_vector(STRSXP, 3);
  r_obj* strings_list_of = r_str("vctrs_list_of");
  r_chr_poke(classes_list_of, 0, strings_list_of);
  r_obj* strings_vctr = r_str("vctrs_vctr");
  r_chr_poke(classes_list_of, 1, strings_vctr);
  r_obj* strings_list = r_str("list");
  r_chr_poke(classes_list_of, 2, strings_list);

  r_preserve_global(strings_empty = r_str(""));
  r_preserve_global(strings_object = r_str("object"));
  r_preserve_global(strings_df = r_str("df"));
  r_preserve_global(strings_row = r_str("row"));

  syms_ptype = r_sym("ptype");
  syms_transform = r_sym("transform");
  syms_value = r_sym("value");
  syms_x = r_sym("x");

  r_obj* vctrs_package = r_env_find(R_NamespaceRegistry, r_sym("vctrs"));
  syms_vec_is = Rf_findFun(r_sym("vec_is"), vctrs_package);

  r_obj* tibblify_symbol = r_sym("tibblify");
  r_obj* tibblify_package = r_env_find(R_NamespaceRegistry, tibblify_symbol);
  syms_vec_flatten = Rf_findFun(r_sym("vec_flatten"), tibblify_package);
}
