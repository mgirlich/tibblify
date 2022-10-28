// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"
#include "finalize.h"


#define ALLOC_SCALAR_COLLECTOR(RTYPE, BEGIN, COLL)             \
  r_obj* col = KEEP(r_alloc_vector(RTYPE, n_rows));            \
  r_list_poke(v_collector->shelter, 0, col);                   \
  v_collector->data = col;                                     \
  v_collector->details.COLL.v_data = BEGIN(col);               \
                                                               \
  v_collector->current_row = 0;                                \
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
  r_obj* col = KEEP(r_alloc_character(n_rows));
  r_list_poke(v_collector->shelter, 0, col);
  v_collector->data = col;

  v_collector->current_row = 0;

  FREE(1);
}

void alloc_coll(struct collector* v_collector, r_ssize n_rows) {
  r_obj* col = KEEP(r_alloc_list(n_rows));
  r_list_poke(v_collector->shelter, 0, col);
  v_collector->data = col;

  v_collector->current_row = 0;

  FREE(1);
}

void alloc_row_collector(struct collector* v_collector, r_ssize n_rows) {
  v_collector->details.multi_coll.n_rows = n_rows;
  r_ssize n_coll = v_collector->details.multi_coll.n_keys;

  struct collector* v_collectors = v_collector->details.multi_coll.collectors;
  for (r_ssize j = 0; j < n_coll; ++j) {
    v_collectors[j].alloc(&v_collectors[j], n_rows);
  }
}

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform,
                                       r_obj* na) {
  r_obj* shelter = KEEP(r_alloc_list(2));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  if (vec_is(ptype_inner, r_globals.empty_lgl)) {
    p_coll->alloc = &alloc_lgl_collector;
    p_coll->add_value = &add_value_lgl;
    p_coll->add_value_colmajor = &add_value_lgl_colmajor;
    p_coll->add_default = &add_default_lgl;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.lgl_coll.default_value = *r_lgl_begin(default_value);
    // `ptype_inner` and `na` don't need to be stored b/c of the appropriate functions used
  } else if (vec_is(ptype_inner, r_globals.empty_int)) {
    p_coll->alloc = &alloc_int_collector;
    p_coll->add_value = &add_value_int;
    p_coll->add_value_colmajor = &add_value_int_colmajor;
    p_coll->add_default = &add_default_int;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.int_coll.default_value = *r_int_begin(default_value);
  } else if (vec_is(ptype_inner, r_globals.empty_dbl)) {
    p_coll->alloc = &alloc_dbl_collector;
    p_coll->add_value = &add_value_dbl;
    p_coll->add_value_colmajor = &add_value_dbl_colmajor;
    p_coll->add_default = &add_default_dbl;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.dbl_coll.default_value = *r_dbl_begin(default_value);
  } else if (vec_is(ptype_inner, r_globals.empty_chr)) {
    p_coll->alloc = &alloc_chr_collector;
    p_coll->add_value = &add_value_chr;
    p_coll->add_value_colmajor = &add_value_chr_colmajor;
    p_coll->add_default = &add_default_chr;
    p_coll->finalize = &finalize_atomic_scalar;
    p_coll->details.chr_coll.default_value = r_chr_get(default_value, 0);
  } else {
    p_coll->alloc = &alloc_coll;
    p_coll->add_value = &add_value_scalar;
    p_coll->add_value_colmajor = &add_value_scalar_colmajor;
    p_coll->add_default = &add_default_scalar;
    p_coll->finalize = &finalize_scalar;
    p_coll->details.scalar_coll.default_value = default_value;
    p_coll->details.scalar_coll.ptype_inner = ptype_inner;
    p_coll->details.scalar_coll.na = na;
  }
  assign_f_absent(p_coll, required);

  p_coll->ptype = ptype;
  p_coll->transform = transform;

  FREE(1);
  return p_coll;
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
                                       r_obj* elt_transform,
                                       r_obj* col_names,
                                       r_obj* list_of_ptype) {
  r_obj* shelter = KEEP(r_alloc_list(3));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->alloc = &alloc_coll;
  p_coll->add_value = &add_value_vector;
  p_coll->add_value_colmajor = &add_value_vector_colmajor;
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
  p_vec_coll->input_form = r_to_vector_form(input_form);
  p_vec_coll->col_names = col_names;
  p_vec_coll->list_of_ptype = list_of_ptype;

  if (names_to != r_null) {
    p_vec_coll->prep_data = &vec_prep_values_names;
  } else if (values_to != r_null) {
    p_vec_coll->prep_data = &vec_prep_values;
  } else {
    p_vec_coll->prep_data = &vec_prep_simple;
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
  p_coll->alloc = &alloc_coll;
  p_coll->add_value = &add_value_variant;
  p_coll->add_value_colmajor = &add_value_variant_colmajor;
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
                                      r_obj* names_col,
                                      r_obj* keys,
                                      r_obj* ptype_dummy,
                                      int n_cols) {
  r_obj* shelter = KEEP(r_alloc_list(5 + n_keys));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;

  switch(coll_type) {
  case COLLECTOR_TYPE_row:
    p_coll->alloc = &alloc_row_collector;
    p_coll->add_value = &add_value_row;
    p_coll->add_value_colmajor = &add_value_row_colmajor;
    p_coll->add_default = &add_default_row;
    p_coll->finalize = &finalize_row;
    break;
  case COLLECTOR_TYPE_df:
    p_coll->alloc = &alloc_coll;
    p_coll->add_value = &add_value_df;
    p_coll->add_default = &add_default_df;
    p_coll->finalize = &finalize_df;
    break;
  default:
    r_stop_internal("Unexpected collector type.");
  }
  assign_f_absent(p_coll, required);
  p_coll->ptype = ptype_dummy;

  r_obj* multi_coll_raw = KEEP(r_alloc_raw(sizeof(struct multi_collector)));
  r_list_poke(shelter, 2, multi_coll_raw);
  struct multi_collector* p_multi_coll = r_raw_begin(multi_coll_raw);
  p_multi_coll->n_keys = n_keys;
  p_multi_coll->keys = keys;

  r_obj* key_match_ind = KEEP(r_alloc_raw(n_keys * sizeof(r_ssize)));
  r_list_poke(p_coll->shelter, 3, key_match_ind);
  p_multi_coll->key_match_ind = key_match_ind;
  int* p_key_match_ind = r_raw_begin(key_match_ind);
  for (int i = 0; i < n_keys; ++i) {
    p_key_match_ind[i] = (r_ssize) i;
  }
  p_multi_coll->p_key_match_ind = p_key_match_ind;

  for (int i = 0; i < 256; ++i) {
    p_multi_coll->field_order_ind[i] = i;
  }

  p_multi_coll->n_cols = n_cols;
  p_multi_coll->col_names = col_names;
  p_multi_coll->coll_locations = coll_locations;
  p_multi_coll->names_col = names_col;
  p_multi_coll->field_names_prev = r_null;

  r_obj* collectors_raw = KEEP(r_alloc_raw(sizeof(struct collector) * n_keys));
  r_list_poke(shelter, 4, collectors_raw);
  p_multi_coll->collectors = r_raw_begin(collectors_raw);

  p_coll->details.multi_coll = *p_multi_coll;

  FREE(4);
  return p_coll;
}

struct collector* new_parser(int n_keys,
                             r_obj* coll_locations,
                             r_obj* col_names,
                             r_obj* names_col,
                             r_obj* keys,
                             r_obj* ptype_dummy,
                             int n_cols) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             false,
                             n_keys,
                             coll_locations,
                             col_names,
                             names_col,
                             keys,
                             ptype_dummy,
                             n_cols);
}

struct collector* new_row_collector(bool required,
                                    int n_keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    r_obj* keys,
                                    r_obj* ptype_dummy,
                                    int n_cols) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             required,
                             n_keys,
                             coll_locations,
                             col_names,
                             r_null,
                             keys,
                             ptype_dummy,
                             n_cols);
}

struct collector* new_df_collector(bool required,
                                   int n_keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   r_obj* names_col,
                                   r_obj* keys,
                                   r_obj* ptype_dummy,
                                   int n_cols) {
  return new_multi_collector(COLLECTOR_TYPE_df,
                             required,
                             n_keys,
                             coll_locations,
                             col_names,
                             names_col,
                             keys,
                             ptype_dummy,
                             n_cols);
}
