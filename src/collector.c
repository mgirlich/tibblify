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

#define INIT_SCALAR_COLLECTOR(RTYPE, BEGIN)                    \
  r_obj* col = KEEP(r_alloc_vector(RTYPE, n_rows));            \
  v_collector->data = col;                                     \
  v_collector->v_data = BEGIN(col);                            \
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

void init_coll(struct collector* v_collector, r_ssize n_rows) {
  r_obj* col = KEEP(r_alloc_list(n_rows));

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

void init_row_collector(struct collector* v_collector, r_ssize n_rows) {
  init_row_collector_impl(v_collector, n_rows);
}

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform) {
  // TODO check size and ptype of `default_value`?
  r_obj* shelter = KEEP(r_alloc_list(2));

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->ptype = ptype;
  p_coll->ptype_inner = ptype_inner;
  p_coll->r_default_value = default_value;
  p_coll->transform = transform;

  if (vec_is(ptype_inner, r_globals.empty_lgl)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_lgl;
    p_coll->default_value = r_lgl_begin(default_value);
    p_coll->init = &init_lgl_collector;
    p_coll->add_value = &add_value_lgl;
    p_coll->add_default = &add_default_lgl;
    p_coll->finalize = &finalize_atomic_scalar;
  } else if (vec_is(ptype_inner, r_globals.empty_int)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_int;
    p_coll->default_value = r_int_begin(default_value);
    p_coll->init = &init_int_collector;
    p_coll->add_value = &add_value_int;
    p_coll->add_default = &add_default_int;
    p_coll->finalize = &finalize_atomic_scalar;
  } else if (vec_is(ptype_inner, r_globals.empty_dbl)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_dbl;
    p_coll->default_value = r_dbl_begin(default_value);
    p_coll->init = &init_dbl_collector;
    p_coll->add_value = &add_value_dbl;
    p_coll->add_default = &add_default_dbl;
    p_coll->finalize = &finalize_atomic_scalar;
  } else if (vec_is(ptype_inner, r_globals.empty_chr)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_chr;
    p_coll->default_value = r_chr_get(default_value, 0);
    p_coll->init = &init_chr_collector;
    p_coll->add_value = &add_value_chr;
    p_coll->add_default = &add_default_chr;
    p_coll->finalize = &finalize_atomic_scalar;
  } else {
    p_coll->coll_type = COLLECTOR_TYPE_scalar;
    p_coll->na = vec_init(ptype_inner, 1);
    p_coll->init = &init_coll;
    p_coll->add_value = &add_value_scalar;
    p_coll->add_default = &add_default_scalar;
    p_coll->finalize = &finalize_scalar;
  }

  if (required) {
    p_coll->add_default_absent = &add_stop_required;
  } else {
    p_coll->add_default_absent = p_coll->add_default;
  }

  FREE(2);
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
                                       r_obj* elt_transform) {
  // TODO check size and ptype of `default_value`?
  r_obj* shelter = KEEP(r_alloc_list(4));

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->ptype = ptype;
  p_coll->ptype_inner = ptype_inner;
  p_coll->r_default_value = default_value;
  p_coll->transform = transform;

  p_coll->init = &init_coll;
  p_coll->add_value = &add_value_vec;
  p_coll->add_default = &add_default_coll;
  p_coll->na = na;

  if (required) {
    p_coll->add_default_absent = &add_stop_required;
  } else {
    p_coll->add_default_absent = p_coll->add_default;
  }

  p_coll->finalize = &finalize_vec;

  r_obj* vec_coll_raw = KEEP(r_alloc_raw(sizeof(struct vector_collector)));
  r_list_poke(shelter, 2, vec_coll_raw);
  struct vector_collector* p_vec_coll = r_raw_begin(vec_coll_raw);

  p_vec_coll->names_to = names_to;
  // bool uses_names_col;
  p_vec_coll->values_to = values_to;
  // bool uses_values_col;
  p_vec_coll->elt_transform = elt_transform;
  p_vec_coll->vector_allows_empty_list = vector_allows_empty_list;
  p_vec_coll->empty_element = vec_init(ptype, 0);

  if (input_form == r_vector_form.vector) {
    p_vec_coll->input_form = VECTOR_FORM_vector;
  } else if (input_form == r_vector_form.scalar_list) {
    p_vec_coll->input_form = VECTOR_FORM_scalar_list;
  } else if (input_form == r_vector_form.object_list) {
    p_vec_coll->input_form = VECTOR_FORM_object;
  } else {
    r_stop_internal("unexpected vector input form");
  }

  if (names_to != r_null) {
    p_vec_coll->prep_data = &vec_prep_values_names;
    r_obj* col_names = KEEP(r_alloc_character(2));
    r_chr_poke(col_names, 0, names_to);
    r_chr_poke(col_names, 1, values_to);
    r_list_poke(shelter, 3, col_names);
    p_vec_coll->col_names = col_names;
    FREE(1);

    r_obj* out_ptype = KEEP(r_alloc_list(2));
    r_attrib_poke_names(out_ptype, col_names);
    r_list_poke(out_ptype, 0, r_globals.empty_chr);
    r_list_poke(out_ptype, 1, ptype);
    r_init_tibble(out_ptype, 0);

    p_vec_coll->list_of_ptype = out_ptype;
    r_list_poke(shelter, 4, out_ptype);
    FREE(1);
  } else if (values_to != r_null) {
    p_vec_coll->prep_data = &vec_prep_values;
    r_obj* col_names = KEEP(r_alloc_character(1));
    r_chr_poke(col_names, 0, values_to);
    r_list_poke(shelter, 3, col_names);
    p_vec_coll->col_names = col_names;
    FREE(1);

    r_obj* out_ptype = KEEP(r_alloc_list(1));
    r_attrib_poke_names(out_ptype, col_names);
    r_list_poke(out_ptype, 0, ptype);
    r_init_tibble(out_ptype, 0);

    p_vec_coll->list_of_ptype = out_ptype;
    r_list_poke(shelter, 4, out_ptype);
    FREE(1);
  } else {
    p_vec_coll->prep_data = &vec_prep_simple;
    p_vec_coll->list_of_ptype = ptype;
  }
  p_coll->details.vector_coll = *p_vec_coll;

  FREE(3);
  return p_coll;
}

struct collector* new_variant_collector(bool required,
                                        r_obj* default_value,
                                        r_obj* transform,
                                        r_obj* elt_transform) {
  // TODO check size and ptype of `default_value`?
  r_obj* shelter = KEEP(r_alloc_list(3));

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->coll_type = COLLECTOR_TYPE_variant;
  p_coll->r_default_value = default_value;
  p_coll->transform = transform;

  r_obj* variant_coll_raw = KEEP(r_alloc_raw(sizeof(struct variant_collector)));
  r_list_poke(shelter, 2, variant_coll_raw);
  struct variant_collector* p_variant_coll = r_raw_begin(variant_coll_raw);
  p_variant_coll->elt_transform = elt_transform;

  p_coll->init = &init_coll;
  p_coll->add_value = &add_value_variant;
  p_coll->add_default = &add_default_coll;
  p_coll->finalize = &finalize_coll;

  if (required) {
    p_coll->add_default_absent = &add_stop_required;
  } else {
    p_coll->add_default_absent = p_coll->add_default;
  }

  FREE(3);
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
    p_coll->init = &init_coll;
    p_coll->add_value = &add_value_df;
    p_coll->add_default = &add_default_df;
    p_coll->finalize = &finalize_coll;
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
