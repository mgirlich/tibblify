// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"
#include "finalize.h"


r_obj* vec_init(r_obj* x, int n) {
  // from https://github.com/r-lib/vctrs/blob/9b65e090da2a0f749c433c698a15d4e259422542/src/names.c#L83
  r_obj* ffi_n = KEEP(r_int(n));
  r_obj* call = KEEP(r_call3(syms_vec_init, syms_x, ffi_n));

  r_obj* mask = KEEP(r_alloc_environment(1, R_GlobalEnv));
  r_env_poke(mask, syms_x, x);
  r_obj* out = KEEP(r_eval(call, mask));

  FREE(4);
  return out;
}

#define ALLOC_SCALAR_COLLECTOR(RTYPE, BEGIN, COLL)              \
  r_obj* col = KEEP(r_alloc_vector(RTYPE, n_rows));            \
  v_collector->data = col;                                     \
  v_collector->details.COLL.v_data = BEGIN(col);               \
                                                               \
  r_list_poke(v_collector->shelter, 0, col);                   \
                                                               \
  FREE(1);

void alloc_lgl_collector(struct collector* v_collector, r_ssize n_rows) {
  ALLOC_SCALAR_COLLECTOR(R_TYPE_logical, r_lgl_begin, lgl_coll);
}
void alloc_int_collector(struct collector* v_collector, r_ssize n_rows) {
  ALLOC_SCALAR_COLLECTOR(R_TYPE_integer, r_int_begin, int_coll);
}
void alloc_dbl_collector(struct collector* v_collector, r_ssize n_rows) {
  ALLOC_SCALAR_COLLECTOR(R_TYPE_double, r_dbl_begin, dbl_coll);
}
void alloc_chr_collector(struct collector* v_collector, r_ssize n_rows) {
  r_obj* col = KEEP(r_alloc_vector(R_TYPE_character, n_rows));
  v_collector->data = col;

  v_collector->current_row = 0;
  r_list_poke(v_collector->shelter, 0, col);

  FREE(1);
}

void alloc_coll(struct collector* v_collector, r_ssize n_rows) {
  r_obj* col = KEEP(r_alloc_list(n_rows));

  v_collector->data = col;
  v_collector->current_row = 0;
  r_list_poke(v_collector->shelter, 0, v_collector->data);

  FREE(1);
}

void alloc_row_collector_impl(struct collector* v_collector, r_ssize n_rows) {
  v_collector->details.multi_coll.n_rows = n_rows;
  r_ssize n_col = v_collector->details.multi_coll.n_keys;

  struct collector* v_collectors = v_collector->details.multi_coll.collectors;
  for (r_ssize j = 0; j < n_col; ++j) {
    r_alloc_integer(10000);
    v_collectors[j].init(&v_collectors[j], n_rows);
    // TODO this is not really needed, right?
    // r_list_poke(df, j, v_collectors[j].data);
  }
}

void alloc_row_collector(struct collector* v_collector, r_ssize n_rows) {
  alloc_row_collector_impl(v_collector, n_rows);
}

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform) {
  // TODO check size and ptype of `default_value`?
  r_obj* shelter = KEEP(r_alloc_list(2));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  if (vec_is(ptype_inner, r_globals.empty_lgl)) {
    p_coll->init = &alloc_lgl_collector;
    p_coll->add_value = &add_value_lgl;
    p_coll->add_default = &add_default_lgl;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.lgl_coll.default_value = *r_lgl_begin(default_value);
  } else if (vec_is(ptype_inner, r_globals.empty_int)) {
    p_coll->init = &alloc_int_collector;
    p_coll->add_value = &add_value_int;
    p_coll->add_default = &add_default_int;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.int_coll.default_value = *r_int_begin(default_value);
  } else if (vec_is(ptype_inner, r_globals.empty_dbl)) {
    p_coll->init = &alloc_dbl_collector;
    p_coll->add_value = &add_value_dbl;
    p_coll->add_default = &add_default_dbl;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.dbl_coll.default_value = *r_dbl_begin(default_value);
  } else if (vec_is(ptype_inner, r_globals.empty_chr)) {
    p_coll->init = &alloc_chr_collector;
    p_coll->add_value = &add_value_chr;
    p_coll->add_default = &add_default_chr;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.chr_coll.default_value = r_chr_get(default_value, 0);
  } else {
    p_coll->init = &alloc_coll;
    p_coll->add_value = &add_value_scalar;
    p_coll->add_default = &add_default_scalar;
    p_coll->finalize = &finalize_scalar;
    p_coll->details.scalar_coll.ptype_inner = ptype_inner;
    p_coll->details.scalar_coll.na = vec_init(ptype_inner, 1);
    p_coll->details.scalar_coll.default_value = default_value;
  }
  assign_f_absent(p_coll, required);

  p_coll->ptype = ptype;
  p_coll->transform = transform;

  FREE(1);
  return p_coll;
}

enum vector_form r_to_vector_form(r_obj* input_form) {
  if (input_form == r_vector_form.vector) {
    return VECTOR_FORM_vector;
  } else if (input_form == r_vector_form.scalar_list) {
    return VECTOR_FORM_scalar_list;
  } else if (input_form == r_vector_form.object_list) {
    return VECTOR_FORM_object;
  } else {
    r_stop_internal("unexpected vector input form");
  }
}

struct collector* new_vector_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform,
                                       r_obj* input_form,
                                       bool vector_allows_empty_list,
                                       r_obj* names_to,
                                       r_obj* values_to,
                                       r_obj* na,
                                       r_obj* elt_transform) {
  r_obj* shelter = KEEP(r_alloc_list(6));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->init = &alloc_coll;
  p_coll->add_value = &add_value_vector;
  p_coll->add_default = &add_default_vector;
  p_coll->finalize = &finalize_vec;
  assign_f_absent(p_coll, required);

  p_coll->ptype = ptype;
  p_coll->transform = transform;

  r_obj* vec_coll_raw = r_alloc_raw(sizeof(struct vector_collector));
  r_list_poke(shelter, 2, vec_coll_raw);
  struct vector_collector* p_vec_coll = r_raw_begin(vec_coll_raw);

  p_vec_coll->ptype_inner = ptype_inner;
  p_vec_coll->default_value = default_value;
  p_vec_coll->na = na;
  p_vec_coll->elt_transform = elt_transform;
  p_vec_coll->vector_allows_empty_list = vector_allows_empty_list;
  p_vec_coll->empty_element = KEEP(vec_init(ptype, 0));
  r_list_poke(p_coll->shelter, 3, p_vec_coll->empty_element);
  FREE(1);
  p_vec_coll->input_form = r_to_vector_form(input_form);

  if (names_to != r_null) {
    p_vec_coll->prep_data = &vec_prep_values_names;
    r_obj* col_names = KEEP(r_alloc_character(2));
    r_obj* names_to_str = KEEP(r_chr_get(names_to, 0));
    r_chr_poke(col_names, 0, names_to_str);
    r_obj* values_to_str = KEEP(r_chr_get(values_to, 0));
    r_chr_poke(col_names, 1, values_to_str);
    r_list_poke(p_coll->shelter, 4, col_names);
    p_vec_coll->col_names = col_names;
    FREE(3);

    r_obj* out_ptype = KEEP(r_alloc_list(2));
    r_attrib_poke_names(out_ptype, col_names);
    r_list_poke(out_ptype, 0, r_globals.empty_chr);
    r_list_poke(out_ptype, 1, ptype);
    r_init_tibble(out_ptype, 0);

    p_vec_coll->list_of_ptype = out_ptype;
    r_list_poke(p_coll->shelter, 5, out_ptype);
    FREE(1);
  } else if (values_to != r_null) {
    p_vec_coll->prep_data = &vec_prep_values;
    r_obj* col_names = KEEP(r_alloc_character(1));
    r_obj* values_to_str = KEEP(r_chr_get(values_to, 0));
    r_chr_poke(col_names, 0, values_to_str);
    r_list_poke(p_coll->shelter, 4, col_names);
    p_vec_coll->col_names = col_names;
    FREE(2);

    r_obj* out_ptype = KEEP(r_alloc_list(1));
    r_attrib_poke_names(out_ptype, col_names);
    r_list_poke(out_ptype, 0, ptype);
    r_init_tibble(out_ptype, 0);

    p_vec_coll->list_of_ptype = out_ptype;
    r_list_poke(p_coll->shelter, 5, out_ptype);
    FREE(1);
  } else {
    p_vec_coll->prep_data = &vec_prep_simple;
    p_vec_coll->list_of_ptype = ptype;
  }
  p_coll->details.vec_coll = *p_vec_coll;

  FREE(1);
  return p_coll;
}

struct collector* new_variant_collector(bool required,
                                        r_obj* default_value,
                                        r_obj* transform,
                                        r_obj* elt_transform) {
  r_obj* shelter = KEEP(r_alloc_list(3));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->init = &alloc_coll;
  p_coll->add_value = &add_value_variant;
  p_coll->add_default = &add_default_variant;
  p_coll->finalize = &finalize_variant;
  assign_f_absent(p_coll, required);

  p_coll->transform = transform;

  r_obj* variant_coll_raw = KEEP(r_alloc_raw(sizeof(struct variant_collector)));
  r_list_poke(p_coll->shelter, 2, variant_coll_raw);
  struct variant_collector* p_variant_coll = r_raw_begin(variant_coll_raw);
  p_variant_coll->elt_transform = elt_transform;
  p_variant_coll->default_value = default_value;

  p_coll->details.variant_coll = *p_variant_coll;

  FREE(2);
  return p_coll;
}

struct collector* new_multi_collector(enum collector_type coll_type,
                                      bool required,
                                      int n_keys,
                                      r_obj* coll_locations,
                                      r_obj* col_names,
                                      r_obj* names_col) {
  r_obj* shelter = KEEP(r_alloc_list(7 + n_keys));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;

  switch(coll_type) {
  case COLLECTOR_TYPE_row:
    p_coll->init = &alloc_row_collector;
    p_coll->add_value = &add_value_row;
    p_coll->add_default = &add_default_row;
    p_coll->finalize = &finalize_row;
    break;
  case COLLECTOR_TYPE_df:
    p_coll->init = &alloc_coll;
    p_coll->add_value = &add_value_df;
    p_coll->add_default = &add_default_df;
    p_coll->finalize = &finalize_df;
    break;
  default:
    r_stop_internal("Unexpected collector type.");
  }
  assign_f_absent(p_coll, required);

  r_obj* multi_coll_raw = KEEP(r_alloc_raw(sizeof(struct multi_collector)));
  r_list_poke(shelter, 2, multi_coll_raw);
  struct multi_collector* p_multi_coll = r_raw_begin(multi_coll_raw);
  p_multi_coll->n_keys = n_keys;
  p_multi_coll->keys = KEEP(r_alloc_character(n_keys));
  r_list_poke(p_coll->shelter, 3, p_multi_coll->keys);

  r_obj* key_match_ind = KEEP(r_alloc_raw(n_keys * sizeof(r_ssize)));
  r_list_poke(p_coll->shelter, 4, key_match_ind);
  p_multi_coll->key_match_ind = key_match_ind;
  int* p_key_match_ind = r_raw_begin(key_match_ind);
  for (int i = 0; i < n_keys; ++i) {
    p_key_match_ind[i] = (r_ssize) i;
  }
  p_multi_coll->p_key_match_ind = p_key_match_ind;

  for (int i = 0; i < 256; ++i) {
    p_multi_coll->field_order_ind[i] = i;
  }

  int n_cols = names_col == r_null ? 0 : 1;;
  for (int i = 0; i < n_keys; ++i) {
    n_cols += r_length(r_list_get(coll_locations, i));
  }
  p_multi_coll->n_cols = n_cols;
  p_multi_coll->col_names = col_names;
  p_multi_coll->coll_locations = coll_locations;
  p_multi_coll->names_col = names_col;
  p_multi_coll->field_names_prev = r_null;

  r_obj* ptype = KEEP(r_alloc_list(n_cols));
  r_list_poke(p_coll->shelter, 5, ptype);
  p_coll->ptype = ptype;

  r_obj* collectors_raw = KEEP(r_alloc_raw(sizeof(struct collector) * n_keys));
  r_list_poke(shelter, 6, collectors_raw);
  p_multi_coll->collectors = r_raw_begin(collectors_raw);

  p_coll->details.multi_coll = *p_multi_coll;

  FREE(6);
  return p_coll;
}

void add_collectors_to_multi_coll(struct collector* coll,
                                  r_obj* keys,
                                  struct collector* collectors) {
  coll->details.multi_coll.keys = keys;
  int n_keys = r_length(keys);
  r_list_poke(coll->shelter, 3, keys);

  coll->details.multi_coll.collectors = collectors;
  for (int i = 0; i < n_keys; ++i) {
    r_list_poke(coll->shelter, 6 + i, collectors[i].shelter);
  }

  // r_obj* ptype = KEEP(r_alloc_list(n_cols));
  // for (int i = 0; i < n_keys; ++i) {
  //   collectors[i].init(&collectors[i], 0);
  //   r_obj* col = KEEP(collectors[i].finalize(&collectors[i]));
  //   // TODO support sub collector
  //   r_obj* ffi_locs = r_list_get(coll_locations, i);
  //   r_list_poke(ptype, r_int_get(ffi_locs, 0), col);
  //   FREE(1);
  // }
  //
  // if (names_col != r_null) {
  //   r_list_poke(ptype, 0, r_globals.empty_chr);
  // }
  //
  // r_attrib_poke_names(ptype, col_names);
  // r_init_tibble(ptype, 0);
  // r_list_poke(out.shelter, 5, ptype);
  // out.ptype = ptype;
  // FREE(1);
}

struct collector* new_parser(int n_keys,
                             r_obj* coll_locations,
                             r_obj* col_names,
                             r_obj* names_col) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             false,
                             n_keys,
                             coll_locations,
                             col_names,
                             names_col);
}

struct collector* new_row_collector(bool required,
                                    int n_keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             required,
                             n_keys,
                             coll_locations,
                             col_names,
                             r_null);
}

struct collector* new_df_collector(bool required,
                                   int n_keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   r_obj* names_col) {
  return new_multi_collector(COLLECTOR_TYPE_df,
                             required,
                             n_keys,
                             coll_locations,
                             col_names,
                             names_col);
}
