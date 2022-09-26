// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"
#include "finalize.h"

/* 1. get number of rows so that we can init data
 * rowmajor -> trivial
 *
 * 2. allocate memory for data
 */

void init_collector_data(r_ssize n_rows, struct collector* v_collector) {
  enum collector_type coll_type = v_collector->coll_type;

  r_obj* col;

  switch(coll_type) {
  case COLLECTOR_TYPE_scalar_lgl:
    col = KEEP(r_alloc_vector(R_TYPE_logical, n_rows));
    v_collector->data = col;
    v_collector->v_data = r_lgl_begin(col);
    break;
  case COLLECTOR_TYPE_scalar_int:
    col = KEEP(r_alloc_vector(R_TYPE_integer, n_rows));
    v_collector->data = col;
    v_collector->v_data = r_int_begin(col);
    break;
  case COLLECTOR_TYPE_scalar_dbl:
    col = KEEP(r_alloc_vector(R_TYPE_double, n_rows));
    v_collector->data = col;
    v_collector->v_data = r_dbl_begin(col);
    break;
  case COLLECTOR_TYPE_scalar_chr:
    col = KEEP(r_alloc_vector(R_TYPE_character, n_rows));
    v_collector->data = col;
    break;
  case COLLECTOR_TYPE_scalar:
  case COLLECTOR_TYPE_vector:
  case COLLECTOR_TYPE_variant:
    col = KEEP(r_alloc_vector(R_TYPE_list, n_rows));
    v_collector->data = col;
    break;

  case COLLECTOR_TYPE_row: {
    r_ssize n_col = v_collector->details.row_coll.n_keys;
    col = KEEP(r_alloc_vector(R_TYPE_list, n_col));
    r_init_tibble(col, n_rows);
    struct collector* v_collectors = v_collector->details.row_coll.collectors;

    for (r_ssize j = 0; j < n_col; ++j) {
      init_collector_data(n_rows, &v_collectors[j]);
      r_list_poke(col, j, v_collectors[j].data);
    }
    v_collector->data = col;
    break;
  }
  }

  r_list_poke(v_collector->shelter, 0, col);

  FREE(1);
}

struct collector* new_scalar_collector(bool required,
                                       int col_location,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value) {
  // TODO should check size of `default_value`

  r_obj* shelter = KEEP(r_alloc_list(5));

  r_list_poke(shelter, 2, ptype);
  r_list_poke(shelter, 3, ptype_inner);
  r_list_poke(shelter, 4, default_value);

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->required = required;
  p_coll->col_location = col_location;
  p_coll->ptype = ptype;
  p_coll->ptype_inner = ptype_inner;
  p_coll->r_default_value = default_value;
  p_coll->current_row = 0;

  if (vec_is(ptype_inner, r_globals.empty_lgl)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_lgl;
    p_coll->default_value = r_lgl_begin(default_value);
    p_coll->add_value = &add_value_lgl;
    p_coll->add_default = &add_default_lgl;
  } else if (vec_is(ptype_inner, r_globals.empty_int)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_int;
    p_coll->add_value = &add_value_int;
    p_coll->add_default = &add_default_int;
  } else if (vec_is(ptype_inner, r_globals.empty_dbl)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_dbl;
    p_coll->add_value = &add_value_dbl;
    p_coll->add_default = &add_default_dbl;
  } else if (vec_is(ptype_inner, r_globals.empty_chr)) {
    p_coll->coll_type = COLLECTOR_TYPE_scalar_chr;
    p_coll->default_value = r_chr_get(default_value, 0);
    p_coll->add_value = &add_value_chr;
    p_coll->add_default = &add_default_chr;
  // } else {
  //   cpp11::sexp na = elt["na"];
  //   col_vec.push_back(Collector_Ptr(new Collector_Scalar(required, location, name, field_args, na)));
  }

  p_coll->finalize = &finalize_scalar;

  FREE(2);
  return p_coll;
}

struct collector* new_row_collector(bool required,
                                    int col_location,
                                    r_obj* keys,
                                    struct collector* collectors) {
  int n_keys = r_length(keys);
  r_obj* shelter = KEEP(r_alloc_list(7 + n_keys));

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  r_list_poke(shelter, 1, coll_raw);
  struct collector* p_coll = r_raw_begin(coll_raw);

  p_coll->shelter = shelter;
  p_coll->coll_type = COLLECTOR_TYPE_row;
  p_coll->required = required;
  p_coll->col_location = col_location;
  p_coll->ptype_inner = r_null;
  p_coll->r_default_value = r_null;
  p_coll->current_row = 0;
  p_coll->add_value = &add_value_row;
  p_coll->add_default = &add_default_row;
  p_coll->finalize = &finalize_row;

  r_obj* key_match_ind = KEEP(r_alloc_raw(n_keys * sizeof(r_ssize)));
  r_list_poke(shelter, 2, key_match_ind);
  r_ssize* p_key_match_ind = r_raw_begin(key_match_ind);

  r_obj* row_coll_raw = KEEP(r_alloc_raw(sizeof(struct row_collector)));
  r_list_poke(shelter, 3, row_coll_raw);
  struct row_collector* p_row_coll = r_raw_begin(row_coll_raw);
  p_row_coll->keys = keys;
  p_row_coll->collectors = collectors;
  p_row_coll->n_keys = n_keys;
  p_row_coll->key_match_ind = key_match_ind;
  p_row_coll->p_key_match_ind = p_key_match_ind;

  p_coll->details.row_coll = *p_row_coll;

  for (int i = 0; i < n_keys; ++i) {
    r_list_poke(shelter, 4 + i, collectors[i].shelter);
    p_key_match_ind[i] = (r_ssize) i;
  }


  FREE(4);
  return p_coll;
}

// r_obj* init_parser_data(r_ssize n_rows, struct collector* collectors, r_ssize n_col) {
//   // TODO can simply use `init_collector_data()` as well?
// }

r_obj* ffi_tibblify(r_obj* data, r_obj* spec) {
  r_ssize n_rows = short_vec_size(data);

  r_obj* key_coll_pair = KEEP(r_alloc_raw(sizeof(struct key_collector_pair)));
  struct key_collector_pair* v_key_coll_pair = r_raw_begin(key_coll_pair);
  *v_key_coll_pair = *parse_fields_spec(spec);

  r_obj* coll_raw = KEEP(r_alloc_raw(sizeof(struct collector)));
  struct collector* p_coll = r_raw_begin(coll_raw);
  *p_coll = *new_row_collector(false,
                               0,
                               v_key_coll_pair->keys,
                               v_key_coll_pair->v_collectors);
  KEEP(p_coll->shelter);
  init_collector_data(n_rows, p_coll);

  r_obj* const * v_data = r_list_cbegin(data);
  for (r_ssize i = 0; i < n_rows; ++i) {
    r_obj* const row = v_data[i];
    p_coll->add_value(p_coll, row);
  }

  p_coll->finalize(p_coll);

  FREE(3);
  return p_coll->data;
}
