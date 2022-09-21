// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "add-value.h"

/* 1. get number of rows so that we can init data
 * rowmajor -> trivial
 *
 * 2. allocate memory for data
 */

r_obj* init_collector_data(r_ssize n_rows, struct collector* v_collector) {
  enum collector_type coll_type = v_collector->coll_type;

  r_obj* col;

  switch(coll_type) {
  case COLLECTOR_TYPE_scalar_lgl:
    col = KEEP(r_alloc_vector(R_TYPE_logical, n_rows));
    v_collector->data = col;
    v_collector->details.scalar_lgl_coll.v_data = r_lgl_begin(col);
    // v_collector->v_data = r_lgl_begin(col);
    break;
  case COLLECTOR_TYPE_scalar_int:
    col = KEEP(r_alloc_vector(R_TYPE_integer, n_rows));
    v_collector->data = col;
    v_collector->details.scalar_int_coll.v_data = r_int_begin(col);
    // v_collector->v_data = r_int_begin(col);
    break;
  case COLLECTOR_TYPE_scalar_dbl:
    col = KEEP(r_alloc_vector(R_TYPE_double, n_rows));
    v_collector->data = col;
    v_collector->details.scalar_dbl_coll.v_data = r_dbl_begin(col);
    // v_collector->v_data = r_dbl_begin(col);
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
    r_obj* collectors = v_collector->details.row_coll.collectors;

    for (r_ssize j = 0; j < n_col; ++j) {
      r_obj* collector_j = r_list_get(collectors, j);
      struct collector* p_collector_j = r_raw_begin(collector_j);

      // TODO maybe use `KEEP_HERE` instead?
      r_obj* col_inner = KEEP(init_collector_data(n_rows, p_collector_j));
      p_collector_j->data = col_inner;
      r_list_poke(col, j, col_inner);
      // `col_inner` is now protected by `data` so can free again
      FREE(1);
    }
    break;
  }
  }

  FREE(1);
  return col;
}

// r_obj* init_parser_data(r_ssize n_rows, struct collector* collectors, r_ssize n_col) {
//   // TODO can simply use `init_collector_data()` as well?
// }

struct collector parse_spect(r_obj* spec) {
  struct collector lgl_coll = {
    .coll_type = COLLECTOR_TYPE_scalar_lgl,
    .required = true,
    .col_location = 1,
    .ptype_inner = r_globals.empty_lgl,

    .current_row = 0,
  };

  struct collector chr_coll = {
    .coll_type = COLLECTOR_TYPE_scalar_chr,
    .required = true,
    .col_location = 2,

    .current_row = 0,
  };

  // RLANG:
  // * use `shelter` to protect from garbage collection
  // * use `raw`

  r_obj* shelter = KEEP(r_alloc_list(1));
  r_ssize n_keys = 2;
  r_obj* collectors = KEEP(r_alloc_list(n_keys));
  r_list_poke(shelter, 0, collectors);
  FREE(1);

  size_t coll_size = sizeof(struct collector);
  // TODO store all collectors directly in a raw
  r_obj* cur_coll = KEEP(r_alloc_raw(coll_size));
  struct collector* test = r_raw_begin(cur_coll);
  memcpy(test, &lgl_coll, coll_size);

  r_list_poke(collectors, 0, cur_coll);
  FREE(1);

  cur_coll = KEEP(r_alloc_raw(coll_size));
  test = r_raw_begin(cur_coll);
  memcpy(test, &chr_coll, coll_size);

  r_list_poke(collectors, 1, cur_coll);
  FREE(1);

  struct collector coll = {
    .coll_type = COLLECTOR_TYPE_row,
    .required = true,
    .col_location = 1,

    .current_row = 0,

    .details.row_coll = {
      .collectors = collectors,
      .n_keys = n_keys,
    },
  };

  return coll;
}

r_obj* ffi_tibblify(r_obj* data) {
  r_ssize n_rows = short_vec_size(data);

  struct collector coll = parse_spect(r_null);
  const r_ssize n_keys = 2;

  r_obj* out = KEEP(init_collector_data(n_rows, &coll));
  r_obj* const * v_data = r_list_cbegin(data);

  for (r_ssize i = 0; i < n_rows; ++i) {
    r_obj* const row = v_data[i];

    for (r_ssize j = 0; j < n_keys; ++j) {
      r_obj* value = r_list_get(row, j);
      r_obj* r_cur_coll = r_list_get(coll.details.row_coll.collectors, j);
      struct collector* cur_coll = r_raw_begin(r_cur_coll);

      if (j == 0) {
        add_value_lgl(cur_coll, value);
      } else {
        add_value_chr(cur_coll, value);
      }
    }
  }

  FREE(2);
  return out;
}

 /*
 *
 * iterate over list elements
 * if key
 */
