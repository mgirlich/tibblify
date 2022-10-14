#ifndef TIBBLIFY_COLLECTOR_H
#define TIBBLIFY_COLLECTOR_H

#include "tibblify.h"
#include "Path.h"

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

struct vector_collector {
  r_obj* list_of_ptype;
  r_obj* col_names;

  enum vector_form input_form;
  // bool uses_names_col;
  r_obj* values_to;
  // bool uses_values_col;
  r_obj* names_to;
  bool vector_allows_empty_list;
  r_obj* empty_element;
  r_obj* elt_transform;

  r_obj* (*prep_data)(r_obj* value_casted, r_obj* names, r_obj* col_names);
};

struct variant_collector {
  r_obj* elt_transform;
};

struct multi_collector {
  r_obj* keys; // strings
  int n_keys;

  r_obj* shelter; // TODO should be able to remove this?!
  struct collector* collectors;
  r_obj* key_match_ind;
  r_ssize* p_key_match_ind;
  int n_fields_prev;
  r_obj* field_names_prev;

  r_ssize n_rows;
  int n_cols;
  r_obj* col_names; // strings
  r_obj* coll_locations; // list - needed to unpack `same_key_collector` columns

  r_obj* names_col;
};

struct collector {
  r_obj* shelter;

  enum collector_type coll_type;
  // r_obj* name;
  r_obj* transform;
  r_obj* ptype;
  r_obj* ptype_inner;
  // TODO store `na` in `collector`?

  r_obj* data;
  void* v_data;
  r_ssize current_row;

  r_obj* na;
  r_obj* r_default_value;
  void* default_value;

  void (*init)(struct collector* v_collector, r_ssize n_rows);
  void (*add_value)(struct collector* v_collector, r_obj* value, struct Path* path);
   // add default value
  void (*add_default)(struct collector* v_collector, struct Path* path);
  // error if required, otherwise add default value
  void (*add_default_absent)(struct collector* v_collector, struct Path* path);
  r_obj* (*finalize)(struct collector* v_collector);

  union details {
    struct vector_collector vector_coll;
    struct variant_collector variant_coll;
    struct multi_collector multi_coll;
  } details;
};

struct collector* new_parser(r_obj* keys,
                             r_obj* coll_locations,
                             r_obj* col_names,
                             struct collector* collectors,
                             r_obj* names_col);

struct collector* new_row_collector(bool required,
                                    r_obj* keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    struct collector* collectors);

struct collector* new_df_collector(bool required,
                                   r_obj* keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   struct collector* collectors,
                                   r_obj* names_col);

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
                                       r_obj* elt_transform);

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform);

struct collector* new_variant_collector(bool required,
                                        r_obj* default_value,
                                        r_obj* transform,
                                        r_obj* elt_transform);

void init_row_collector(struct collector* v_collector, r_ssize n_rows);

r_obj* ffi_tibblify(r_obj* data, r_obj* spec, r_obj* path_xptr);

#endif
