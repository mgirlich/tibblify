// #include <plogr.h>
#include "tibblify.h"

enum parser_type {
  PARSER_TYPE_df     = 0,
  PARSER_TYPE_row    = 1,
  PARSER_TYPE_object = 2
};

// struct parser {
//
// };

enum collector_type {
  COLLECTOR_TYPE_scalar = 0,
  COLLECTOR_TYPE_vector = 1,
  COLLECTOR_TYPE_row    = 2
};

struct scalar_collector_atomic {
  r_obj* na;
  enum r_type type;
};

struct scalar_collector {
  r_obj* na;
};

struct vector_collector {
  r_obj* na;

  // vector_input_form input_form;
  bool uses_names_col;
  bool uses_values_col;
  r_obj* output_col_names;
  bool vector_allows_empty_list;
  r_obj* empty_element;
  r_obj* elt_transform;
};

struct list_collector {
  r_obj* elt_transform;
};

struct row_collector {
  r_obj* keys; // strings
  // std::vector<Collector_Ptr> collector_vec;
  struct collector* collectors;
  const int n_keys;
};

struct collector {
  const enum collector_type clt_type;
  const bool required;
  const int col_location;
  r_obj* name;
  r_obj* transform;
  r_obj* default_value;
  r_obj* ptype;
  r_obj* ptype_inner;

  r_obj* data;

  union details {
    struct scalar_collector_atomic scalaratomic_clt;
    struct row_collector row_clt;
  } details;
};

/* 1. get number of rows so that we can init data
 * rowmajor -> trivial
 *
 * 2. allocate memory for data
 */

enum r_type collector_storage_type(struct collector* v_collector) {
  enum collector_type clt_type = v_collector->clt_type;

  switch(clt_type) {
  case COLLECTOR_TYPE_scalar: {
    return v_collector->details.scalaratomic_clt.type;
    break;
  }
  case COLLECTOR_TYPE_vector:
  case COLLECTOR_TYPE_row: {
    return R_TYPE_list;
    break;
  }
  }
}

r_obj* init_collector_data(r_ssize n_rows, struct collector* v_collector) {
  enum collector_type clt_type = v_collector->clt_type;

  enum r_type storage_type = collector_storage_type(v_collector);
  r_obj* col = KEEP(r_alloc_vector(storage_type, n_rows));

  switch(clt_type) {
  case COLLECTOR_TYPE_scalar:
  case COLLECTOR_TYPE_vector: {
    v_collector->data = col;
    break;
  }

  case COLLECTOR_TYPE_row: {
    r_ssize n_col = v_collector->details.row_clt.n_keys;
    struct collector* collectors = v_collector->details.row_clt.collectors;

    for (r_ssize j = 0; j < n_col; ++j) {
      r_obj* col_inner = KEEP(init_collector_data(n_rows, &collectors[j]));
      collectors[j].data = col_inner;
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

r_obj* init_parser_data(r_ssize n_rows, struct collector* collectors, r_ssize n_col) {
  // TODO can simply use `init_collector_data()` as well?
  r_obj* out = KEEP(r_alloc_list(n_col));

  for (r_ssize j = 0; j < n_col; ++j) {
    r_obj* col = KEEP(init_collector_data(n_rows, &collectors[j]));
    collectors[j].data = col;
    r_list_poke(out, j, col);
    // `col` is now protected by `data` so can free again
    FREE(1);
  }

  FREE(1);
  return out;
}

void add_value_scalar(struct collector* v_collector) {
  if (value == r_null) {
    // TODO store `na` in `collector`?
    v_collector->data_ptr = v_collector->details.scalaratomic_clt.na;
    // ++(*v_collector)->data_ptr;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, v_collector->details.scalaratomic_clt.ptype_inner));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    // stop_scalar(path, size);
  }


  switch (*v_collector)

  v_collector->data_ptr = r_vector_cast<T, CPP11_TYPE>(value_casted);
  // ++(*v_collector)->data_ptr;
  FREE(1);

  // TODO assign to `data_pointer`
  // (*v_collector)->data
}

void add_value(r_obj* col, r_obj* value, r_ssize row_index) {

}

r_obj* tibblify2() {
  // TODO parse spec
  // TODO get `n_rows`

  r_obj* out = KEEP(init_parser_data(n_rows, collectors, n_col));


}

 /*
 *
 * iterate over list elements
 * if key
 */
