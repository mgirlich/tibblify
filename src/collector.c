// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "conditions.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"
#include "finalize.h"


// for colmajor there is no need to allocate space
#define ALLOC_SCALAR_COLLECTOR(RTYPE, BEGIN, COLL)             \
  v_collector->current_row = 0;                                \
                                                               \
  if (!v_collector->rowmajor) {                                \
    return;                                                    \
  }                                                            \
                                                               \
  r_obj* col = KEEP(r_alloc_vector(RTYPE, n_rows));            \
  r_list_poke(v_collector->shelter, 0, col);                   \
  v_collector->data = col;                                     \
  v_collector->details.COLL.v_data = BEGIN(col);               \
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
  v_collector->current_row = 0;

  if (!v_collector->rowmajor) {
    return;
  }

  r_obj* col = KEEP(r_alloc_character(n_rows));
  r_list_poke(v_collector->shelter, 0, col);
  v_collector->data = col;

  FREE(1);
}

void alloc_vector_coll(struct collector* v_collector, r_ssize n_rows) {
  v_collector->current_row = 0;

  r_obj* col = KEEP(r_alloc_list(n_rows));
  r_list_poke(v_collector->shelter, 0, col);
  v_collector->data = col;

  FREE(1);
}

void alloc_scalar_coll(struct collector* v_collector, r_ssize n_rows) {
  v_collector->current_row = 0;

  if (!v_collector->rowmajor) {
    return;
  }

  r_obj* col = KEEP(r_alloc_list(n_rows));
  r_list_poke(v_collector->shelter, 0, col);
  v_collector->data = col;

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

void alloc_coll_df(struct collector* v_collector, r_ssize n_rows) {
  v_collector->current_row = 0;

  r_obj* col = KEEP(r_alloc_list(n_rows));
  r_list_poke(v_collector->shelter, 0, col);
  v_collector->data = col;

  FREE(1);
}

void colmajor_nrows_coll(struct collector* v_collector, r_obj* value, r_ssize* n_rows, struct Path* path, struct Path* nrow_path) {
  if (value == r_null) {
    stop_colmajor_null(path->data);
  }

  r_ssize n_value = short_vec_size(value);
  check_colmajor_size(n_value, n_rows, path, nrow_path);
}

void colmajor_nrows_row(struct collector* v_collector, r_obj* value, r_ssize* n_rows, struct Path* path, struct Path* nrow_path) {
  r_ssize n_value = get_collector_vec_rows(v_collector, value, n_rows, path, nrow_path);
  check_colmajor_size(n_value, n_rows, path, nrow_path);
}

r_ssize get_collector_vec_rows(struct collector* v_collector,
                               r_obj* object_list,
                               r_ssize* n_rows,
                               struct Path* path,
                               struct Path* nrow_path) {
  if (r_typeof(object_list) != R_TYPE_list) {
    // TODO error message should mention why it has to be a list
    stop_colmajor_non_list_element(path->data, object_list);
  }

  r_obj* field_names = r_names(object_list);
  const r_ssize n_fields = short_vec_size(object_list);

  if (n_fields == 0) {
    // TODO check if this makes sense...
    *n_rows = 0;
    return *n_rows;
  }

  struct multi_collector* v_multi_coll = &v_collector->details.multi_coll;
  match_chr(v_multi_coll->keys,
            field_names,
            v_multi_coll->p_key_match_ind,
            r_length(field_names));

  r_obj* const * v_object_list = r_list_cbegin(object_list);
  r_obj* const * v_keys = r_chr_cbegin(v_multi_coll->keys);
  struct collector* v_collectors = v_multi_coll->collectors;

  path_down(path);
  for (int key_index = 0; key_index < v_multi_coll->n_keys; ++key_index) {
    int loc = v_multi_coll->p_key_match_ind[key_index];
    r_obj* cur_key = v_keys[key_index];
    path_replace_key(path, cur_key);

    if (loc < 0) {
      stop_required_colmajor(path->data);
    }

    r_obj* field = v_object_list[loc];
    struct collector* v_coll_cur = &v_collectors[key_index];
    v_coll_cur->check_colmajor_nrows(v_coll_cur, field, n_rows, path, nrow_path);
  }
  path_up(path);

  return *n_rows;
}

r_obj* get_ptype_scalar(struct collector* v_collector) {
  return v_collector->ptype;
}

r_obj* get_ptype_vector(struct collector* v_collector) {
  return v_collector->details.vec_coll.list_of_ptype;
}

r_obj* get_ptype_variant(struct collector* v_collector) {
  return r_globals.empty_list;
}

r_obj* get_ptype_row(struct collector* v_collector) {
  struct multi_collector* p_multi_coll = &v_collector->details.multi_coll;
  r_ssize n_cols = p_multi_coll->n_cols;
  r_obj* df = KEEP(r_alloc_list(n_cols));
  r_attrib_poke_names(df, p_multi_coll->col_names);

  struct collector* v_collectors = p_multi_coll->collectors;
  for (r_ssize i = 0; i < p_multi_coll->n_keys; ++i) {
    struct collector* v_coll_i = &v_collectors[i];
    r_obj* col = KEEP(v_coll_i->get_ptype(v_coll_i));

    r_obj* ffi_locs = r_list_get(p_multi_coll->coll_locations, i);
    assign_in_multi_collector(df, col, v_coll_i->unpack, ffi_locs);
    FREE(1);
  }

  if (p_multi_coll->names_col != r_null) {
    r_list_poke(df, 0, r_globals.empty_chr);
  }

  r_init_tibble(df, 0);

  FREE(1);
  return df;
}

r_obj* get_ptype_df(struct collector* v_collector) {
  r_obj* ptype = KEEP(r_alloc_list(0));

  r_attrib_poke_class(ptype, classes_list_of);
  r_obj* list_of_ptype = KEEP(get_ptype_row(v_collector));
  r_attrib_poke(ptype, syms_ptype, list_of_ptype);

  FREE(1);
  return ptype;
}

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform,
                                       r_obj* na,
                                       bool rowmajor) {
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
    p_coll->alloc = &alloc_scalar_coll;
    p_coll->add_value = &add_value_scalar;
    p_coll->add_value_colmajor = &add_value_scalar_colmajor;
    p_coll->add_default = &add_default_scalar;
    p_coll->finalize = &finalize_scalar;
    p_coll->details.scalar_coll.default_value = default_value;
    p_coll->details.scalar_coll.ptype_inner = ptype_inner;
    p_coll->details.scalar_coll.na = na;
  }
  p_coll->check_colmajor_nrows = &colmajor_nrows_coll;
  p_coll->get_ptype = &get_ptype_scalar;
  p_coll->rowmajor = rowmajor;
  p_coll->unpack = false;
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
                                       r_obj* list_of_ptype,
                                       bool rowmajor) {
  r_obj* shelter = KEEP(r_alloc_list(3));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->get_ptype = &get_ptype_vector;
  p_coll->alloc = &alloc_vector_coll;
  p_coll->add_value = &add_value_vector;
  p_coll->add_value_colmajor = &add_value_vector_colmajor;
  p_coll->add_default = &add_default_vector;
  p_coll->finalize = &finalize_vec;
  p_coll->check_colmajor_nrows = &colmajor_nrows_coll;
  p_coll->rowmajor = rowmajor;
  p_coll->unpack = false;
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
                                        r_obj* elt_transform,
                                        bool rowmajor) {
  r_obj* shelter = KEEP(r_alloc_list(3));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->get_ptype = &get_ptype_variant;
  p_coll->alloc = &alloc_vector_coll;
  p_coll->add_value = &add_value_variant;
  p_coll->add_value_colmajor = &add_value_variant_colmajor;
  p_coll->add_default = &add_default_variant;
  p_coll->finalize = &finalize_variant;
  p_coll->check_colmajor_nrows = &colmajor_nrows_coll;
  p_coll->rowmajor = rowmajor;
  p_coll->unpack = false;
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
                                      int n_cols,
                                      bool rowmajor) {
  r_obj* shelter = KEEP(r_alloc_list(5 + n_keys));

  r_obj* coll_raw = r_alloc_raw(sizeof(struct collector));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;

  switch(coll_type) {
  case COLLECTOR_TYPE_sub:
  case COLLECTOR_TYPE_row:
    p_coll->get_ptype = &get_ptype_row;
    p_coll->alloc = &alloc_row_collector;
    p_coll->add_value = &add_value_row;
    p_coll->add_value_colmajor = &add_value_row_colmajor;
    p_coll->add_default = &add_default_row;
    p_coll->finalize = &finalize_row;
    p_coll->check_colmajor_nrows = &colmajor_nrows_row;
    p_coll->unpack = coll_type == COLLECTOR_TYPE_sub;
    break;
  case COLLECTOR_TYPE_df:
    p_coll->get_ptype = &get_ptype_df;
    p_coll->alloc = &alloc_coll_df;
    p_coll->add_value = &add_value_df;
    p_coll->add_value_colmajor = &add_value_df_colmajor;
    p_coll->add_default = &add_default_df;
    p_coll->finalize = &finalize_df;
    p_coll->check_colmajor_nrows = &colmajor_nrows_coll;
    p_coll->unpack = false;
    break;
  default:
    r_stop_internal("Unexpected collector type.");
  }

  assign_f_absent(p_coll, required);
  p_coll->ptype = ptype_dummy;
  p_coll->rowmajor = rowmajor;

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
  p_multi_coll->field_names_prev = r_globals.empty_chr;

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
                             int n_cols,
                             bool rowmajor) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             false,
                             n_keys,
                             coll_locations,
                             col_names,
                             names_col,
                             keys,
                             ptype_dummy,
                             n_cols,
                             rowmajor);
}

struct collector* new_row_collector(bool required,
                                    int n_keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    r_obj* keys,
                                    r_obj* ptype_dummy,
                                    int n_cols,
                                    bool rowmajor) {
  return new_multi_collector(COLLECTOR_TYPE_row,
                             required,
                             n_keys,
                             coll_locations,
                             col_names,
                             r_null,
                             keys,
                             ptype_dummy,
                             n_cols,
                             rowmajor);
}

struct collector* new_sub_collector(int n_keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    r_obj* keys,
                                    r_obj* ptype_dummy,
                                    int n_cols,
                                    bool rowmajor) {
  return new_multi_collector(COLLECTOR_TYPE_sub,
                             false,
                             n_keys,
                             coll_locations,
                             col_names,
                             r_null,
                             keys,
                             ptype_dummy,
                             n_cols,
                             rowmajor);
}

struct collector* new_df_collector(bool required,
                                   int n_keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   r_obj* names_col,
                                   r_obj* keys,
                                   r_obj* ptype_dummy,
                                   int n_cols,
                                   bool rowmajor) {
  return new_multi_collector(COLLECTOR_TYPE_df,
                             required,
                             n_keys,
                             coll_locations,
                             col_names,
                             names_col,
                             keys,
                             ptype_dummy,
                             n_cols,
                             rowmajor);
}

void assign_in_multi_collector(r_obj* x, r_obj* xi, bool unpack, r_obj* ffi_locs) {
  // The sub collector is basically the same as the row collector but the fields
  // should not become columns. Rather they are into the parent structure.
  if (unpack) {
    r_ssize n_locs = short_vec_size(ffi_locs);
    for (r_ssize j = 0; j < n_locs; ++j) {
      int loc = r_int_get(ffi_locs, j);
      r_obj* val = r_list_get(xi, j);
      r_list_poke(x, loc, val);
    }
  } else {
    r_list_poke(x, r_int_get(ffi_locs, 0), xi);
  }
}
