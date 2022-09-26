#ifndef TIBBLIFY_COLLECTOR_H
#define TIBBLIFY_COLLECTOR_H

#include "tibblify.h"

enum vector_form {
  VECTOR_FORM_vector      = 0,
  VECTOR_FORM_scalar_list = 1,
  VECTOR_FORM_object      = 2,
};

enum parser_type {
  PARSER_TYPE_df     = 0,
  PARSER_TYPE_row    = 1,
  PARSER_TYPE_object = 2,
};

// struct parser {
//
// };

enum collector_type {
  COLLECTOR_TYPE_scalar        = 0,
  COLLECTOR_TYPE_scalar_lgl    = 1,
  COLLECTOR_TYPE_scalar_int    = 2,
  COLLECTOR_TYPE_scalar_dbl    = 3,
  // COLLECTOR_TYPE_scalar_cpl    = 4,
  // COLLECTOR_TYPE_scalar_raw    = 5,
  COLLECTOR_TYPE_scalar_chr    = 6,
  COLLECTOR_TYPE_vector        = 7,
  COLLECTOR_TYPE_variant       = 8,
  COLLECTOR_TYPE_row           = 9,
  // COLLECTOR_TYPE_tibble        = 10,
};

struct scalar_collector {
  r_obj* na;
};

// struct scalar_lgl_collector {
// };
//
// struct scalar_int_collector {
// };
//
// struct scalar_dbl_collector {
// };

struct vector_collector {
  r_obj* na;

  enum vector_form input_form;
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

  // struct collector* collector_vec;
  // std::vector<Collector_Ptr> collector_vec;
  // r_obj* collectors;
  r_obj* shelter;
  struct collector* collectors;
  int n_keys;
  r_obj* key_match_ind;
  r_ssize* p_key_match_ind;
};

struct collector {
  r_obj* shelter;

  enum collector_type coll_type;
  bool required;
  int col_location;
  // r_obj* name;
  // r_obj* transform;
  // r_obj* default_value;
  r_obj* ptype;
  r_obj* ptype_inner;
  // TODO store `na` in `collector`?

  r_obj* data;
  void* v_data;
  r_ssize current_row;

  r_obj* r_default_value;
  void* default_value;

  void (*add_value)(struct collector* v_collector, r_obj* value);
  void (*add_default)(struct collector* v_collector, const bool check);
  void (*finalize)(struct collector* v_collector);

  union details {
    // struct scalar_lgl_collector scalar_lgl_coll;
    // struct scalar_int_collector scalar_int_coll;
    // struct scalar_dbl_collector scalar_dbl_coll;
    struct scalar_collector scalar_coll;
    struct row_collector row_coll;
  } details;
};

static inline
void* collector_pointer(struct collector* p_coll, int i) {
  int offset = i * sizeof(struct collector);
  return p_coll + offset;
}

struct collector* new_row_collector(bool required,
                                    int col_location,
                                    r_obj* keys,
                                    struct collector* collectors);

struct collector* new_scalar_collector(bool required,
                                       int col_location,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value);

r_obj* ffi_tibblify(r_obj* data, r_obj* spec);

#endif
