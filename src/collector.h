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
  COLLECTOR_TYPE_df            = 10,
};

struct scalar_collector {
  r_obj* na;
};

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

struct multi_collector {
  r_obj* keys; // strings
  int n_keys;

  r_obj* shelter; // TODO should be able to remove this?!
  struct collector* collectors;
  r_obj* key_match_ind;
  r_ssize* p_key_match_ind;

  r_ssize n_rows;
  int n_cols;
  r_obj* col_names; // strings
  r_obj* coll_locations; // list - needed to unpack `same_key_collector` columns
};

struct collector {
  r_obj* shelter;

  enum collector_type coll_type;
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

  void (*init)(struct collector* v_collector, r_ssize n_rows);
  void (*add_value)(struct collector* v_collector, r_obj* value);
   // add default value
  void (*add_default)(struct collector* v_collector);
  // error if required, otherwise add default value
  void (*add_default_absent)(struct collector* v_collector);
  r_obj* (*finalize)(struct collector* v_collector);

  union details {
    struct scalar_collector scalar_coll;
    struct multi_collector multi_coll;
  } details;
};

struct collector* new_row_collector(bool required,
                                    r_obj* keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    struct collector* collectors);

struct collector* new_df_collector(bool required,
                                   r_obj* keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   struct collector* collectors);

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value);

void init_lgl_collector(struct collector* v_collector, r_ssize n_rows);
void init_int_collector(struct collector* v_collector, r_ssize n_rows);
void init_dbl_collector(struct collector* v_collector, r_ssize n_rows);
void init_chr_collector(struct collector* v_collector, r_ssize n_rows);
void init_row_collector(struct collector* v_collector, r_ssize n_rows);
void init_df_collector(struct collector* v_collector, r_ssize n_rows);

r_obj* ffi_tibblify(r_obj* data, r_obj* spec);

#endif
