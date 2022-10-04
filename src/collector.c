// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"
#include "finalize.h"


#define INIT_SCALAR_COLLECTOR(RTYPE, BEGIN)                     \
  r_obj* col = KEEP(r_alloc_vector(RTYPE, n_rows));            \
  v_collector->data = col;                                     \
  v_collector->v_data = BEGIN(col);              \
                                                               \
  v_collector->current_row = 0;                                \
  r_list_poke(v_collector->shelter, 0, col);                   \
                                                               \
  FREE(1);

void init_lgl_collector(struct collector* v_collector, r_ssize n_rows) {
  INIT_SCALAR_COLLECTOR(R_TYPE_logical, r_lgl_begin);
}
void init_int_collector(struct collector* v_collector, r_ssize n_rows) {
  INIT_SCALAR_COLLECTOR(R_TYPE_integer, r_int_begin);
}
void init_dbl_collector(struct collector* v_collector, r_ssize n_rows) {
  INIT_SCALAR_COLLECTOR(R_TYPE_double, r_dbl_begin);
}
void init_chr_collector(struct collector* v_collector, r_ssize n_rows) {
  r_obj* col = KEEP(r_alloc_vector(R_TYPE_character, n_rows));
  v_collector->data = col;

  v_collector->current_row = 0;
  r_list_poke(v_collector->shelter, 0, col);

  FREE(1);
}

void init_row_collector_impl(struct collector* v_collector, r_ssize n_rows) {
  // r_printf("init_row_collector()\n");
  v_collector->details.multi_coll.n_rows = n_rows;
  r_ssize n_col = v_collector->details.multi_coll.n_keys;

  struct collector* v_collectors = v_collector->details.multi_coll.collectors;
  for (r_ssize j = 0; j < n_col; ++j) {
    // r_printf("* ");
    v_collectors[j].init(&v_collectors[j], n_rows);
    // TODO this is not really needed, right?
    // r_list_poke(df, j, v_collectors[j].data);
  }

  // v_collector->current_row = 0;
  // r_list_poke(v_collector->shelter, 0, df);

  // r_printf("init_row_collector() -> done\n");

  // return df;
}

void init_collector(struct collector* v_collector, r_ssize n_rows) {
  r_obj* col = KEEP(r_alloc_list(n_rows));
  v_collector->data = col;
  v_collector->current_row = 0;
  r_list_poke(v_collector->shelter, 0, col);
}

void init_row_collector(struct collector* v_collector, r_ssize n_rows) {
  init_row_collector_impl(v_collector, n_rows);
}

void init_df_collector(struct collector* v_collector, r_ssize n_rows) {
  // r_printf("init_df_collector()\n");
  r_obj* col = KEEP(r_alloc_list(n_rows));

  v_collector->data = col;
  v_collector->current_row = 0;
  r_list_poke(v_collector->shelter, 0, col);

  FREE(1);
}

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value) {
  // TODO check size and ptype of `default_value`?
  r_obj* shelter = KEEP(r_alloc_list(5));

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);
  r_list_poke(shelter, 2, ptype);
  r_list_poke(shelter, 3, ptype_inner);
  r_list_poke(shelter, 4, default_value);

  p_coll->shelter = shelter;
  p_coll->ptype = ptype;
  p_coll->ptype_inner = ptype_inner;
  p_coll->r_default_value = default_value;

  if (vec_is(ptype_inner, r_globals.empty_lgl)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_lgl;
    p_coll->default_value = r_lgl_begin(default_value);
    p_coll->init = &init_lgl_collector;
    p_coll->add_value = &add_value_lgl;
    p_coll->add_default = &add_default_lgl;
  } else if (vec_is(ptype_inner, r_globals.empty_int)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_int;
    p_coll->init = &init_int_collector;
    p_coll->add_value = &add_value_int;
    p_coll->add_default = &add_default_int;
  } else if (vec_is(ptype_inner, r_globals.empty_dbl)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_dbl;
    p_coll->init = &init_dbl_collector;
    p_coll->add_value = &add_value_dbl;
    p_coll->add_default = &add_default_dbl;
  } else if (vec_is(ptype_inner, r_globals.empty_chr)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_chr;
    p_coll->default_value = r_chr_get(default_value, 0);
    p_coll->init = &init_chr_collector;
    p_coll->add_value = &add_value_chr;
    p_coll->add_default = &add_default_chr;
  // } else {
  //   cpp11::sexp na = elt["na"];
  //   col_vec.push_back(Collector_Ptr(new Collector_Scalar(required, location, name, field_args, na)));
  }

  if (required) {
    p_coll->add_default_absent = &add_stop_required;
  } else {
    p_coll->add_default_absent = p_coll->add_default;
  }

  p_coll->finalize = &finalize_scalar;

  FREE(2);
  return p_coll;
}

struct collector* new_multi_collector(enum collector_type coll_type,
                                      bool required,
                                      r_obj* keys,
                                      r_obj* coll_locations,
                                      r_obj* col_names,
                                      struct collector* collectors) {
  int n_keys = r_length(keys);
  r_obj* shelter = KEEP(r_alloc_list(4 + n_keys));

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->coll_type = coll_type;
  p_coll->ptype_inner = r_null;
  p_coll->r_default_value = r_null;

  switch(coll_type) {
  case COLLECTOR_TYPE_row:
    p_coll->init = &init_row_collector;
    p_coll->add_value = &add_value_row;
    p_coll->add_default = &add_default_row;
    p_coll->finalize = &finalize_row;
    break;
  case COLLECTOR_TYPE_df:
    p_coll->init = &init_df_collector;
    p_coll->add_value = &add_value_df;
    p_coll->add_default = &add_default_df;
    p_coll->finalize = &finalize_df;
    break;
  default:
    r_stop_internal("Unexpected collector type.");
  }

  if (required) {
    p_coll->add_default_absent = &add_stop_required;
  } else {
    p_coll->add_default_absent = p_coll->add_default;
  }

  r_obj* multi_coll_raw = KEEP(r_alloc_raw(sizeof(struct multi_collector)));
  r_list_poke(shelter, 2, multi_coll_raw);
  struct multi_collector* p_multi_coll = r_raw_begin(multi_coll_raw);
  p_multi_coll->keys = keys;
  p_multi_coll->collectors = collectors;
  for (int i = 0; i < n_keys; ++i) {
    r_list_poke(shelter, 3 + i, collectors[i].shelter);
  }
  p_multi_coll->n_keys = n_keys;

  r_obj* key_match_ind = KEEP(r_alloc_raw(n_keys * sizeof(r_ssize)));
  r_list_poke(shelter, 4, key_match_ind);
  p_multi_coll->key_match_ind = key_match_ind;
  r_ssize* p_key_match_ind = r_raw_begin(key_match_ind);
  for (int i = 0; i < n_keys; ++i) {
    p_key_match_ind[i] = (r_ssize) i;
  }
  p_multi_coll->p_key_match_ind = p_key_match_ind;

  int n_cols = 0;
  for (int i = 0; i < n_keys; ++i) {
    n_cols += r_length(r_list_get(coll_locations, i));
  }
  p_multi_coll->n_cols = n_cols;
  p_multi_coll->col_names = col_names;
  p_multi_coll->coll_locations = coll_locations;

  p_coll->details.multi_coll = *p_multi_coll;

  FREE(4);
  return p_coll;
}

struct collector* new_row_collector(bool required,
                                    r_obj* keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    struct collector* collectors) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             required,
                             keys,
                             coll_locations,
                             col_names,
                             collectors);
}

struct collector* new_df_collector(bool required,
                                   r_obj* keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   struct collector* collectors) {
  return new_multi_collector(COLLECTOR_TYPE_df,
                             required,
                             keys,
                             coll_locations,
                             col_names,
                             collectors);
}
