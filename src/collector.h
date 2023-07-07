#ifndef TIBBLIFY_COLLECTOR_H
#define TIBBLIFY_COLLECTOR_H

#include "Path.h"
#include "tibblify.h"

enum vector_form {
  VECTOR_FORM_vector      = 0,
  VECTOR_FORM_scalar_list = 1,
  VECTOR_FORM_object      = 2,
};

static inline
enum vector_form r_to_vector_form(r_obj* input_form) {
  if (input_form == r_vector_form.vector) {
    return VECTOR_FORM_vector;
  } else if (input_form == r_vector_form.scalar_list) {
    return VECTOR_FORM_scalar_list;
  } else if (input_form == r_vector_form.object_list) {
    return VECTOR_FORM_object;
  } else {
    r_stop_internal("unexpected vector input form"); // # nocov
  }
}

static inline
r_obj* vector_input_form_to_sexp(enum vector_form input_form) {
  switch (input_form) {
  case VECTOR_FORM_vector: return r_chr("vector"); // # nocov
  case VECTOR_FORM_scalar_list: return r_chr("scalar_list");
  case VECTOR_FORM_object: return r_chr("object");
  }

  r_stop_unreachable(); // # nocov
}

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
  COLLECTOR_TYPE_sub           = 9,
  COLLECTOR_TYPE_row           = 10,
  COLLECTOR_TYPE_df            = 11,
  COLLECTOR_TYPE_recursive     = 12,
};

struct lgl_collector {
  int* v_data;
  int default_value;
};

struct int_collector {
  int* v_data;
  int default_value;
};

struct dbl_collector {
  double* v_data;
  double default_value;
};

struct chr_collector {
  r_obj* default_value;
};

struct scalar_collector {
  r_obj* default_value;
  r_obj* ptype_inner;
  r_obj* na;
};

struct vector_collector {
  r_obj* ptype_inner;
  r_obj* default_value;

  r_obj* list_of_ptype;
  r_obj* col_names;

  r_obj* na;

  enum vector_form input_form;
  bool vector_allows_empty_list;
  r_obj* elt_transform;

  r_obj* (*prep_data)(r_obj* value_casted, r_obj* names, r_obj* col_names);
};

struct variant_collector {
  r_obj* default_value;
  r_obj* elt_transform;
};

struct multi_collector {
  r_obj* keys; // strings
  int n_keys;

  struct collector* collectors;
  int field_order_ind[256];
  r_obj* key_match_ind;
  int* p_key_match_ind;
  r_obj* field_names_prev;

  r_ssize n_rows;
  int n_cols;
  r_obj* col_names; // strings
  r_obj* coll_locations; // list - needed to unpack `same_key_collector` columns

  r_obj* names_col;
};

struct recursive_collector {
  struct collector* v_parent;
};

struct collector {
  r_obj* shelter;

  void (*alloc)(struct collector* v_collector, r_ssize n_rows);
  void (*add_value)(struct collector* v_collector, r_obj* value, struct Path* v_path);
  void (*add_value_colmajor)(struct collector* v_collector, r_obj* value, struct Path* v_path);
  // check if `value` has size `n_rows`
  void (*check_colmajor_nrows)(struct collector* v_collector, r_obj* value, r_ssize* n_rows, struct Path* v_path, struct Path* nrow_path);
  // add default value
  void (*add_default)(struct collector* v_collector, struct Path* v_path);
  // error if required, otherwise add default value
  void (*add_default_absent)(struct collector* v_collector, struct Path* v_path);
  r_obj* (*finalize)(struct collector* v_collector);
  // get the prototype of the collector. This is needed to set the right ptype
  // in the <list_of> column created in the `finalize()` step of the df collector.
  // This can't be calculated from the elements as they might all be NULL.
  // FIXME it might be easier to calculate this in R
  r_obj* (*get_ptype)(struct collector* v_collector);
  // `copy()` is needed in the recursive parser so that the collectors aren't
  // overwritten.
  struct collector* (*copy)(struct collector* v_collector);
  bool rowmajor;
  bool unpack;

  r_obj* transform;
  r_obj* ptype;

  r_obj* data;
  r_ssize current_row;

  union details {
    struct lgl_collector lgl_coll;
    struct int_collector int_coll;
    struct dbl_collector dbl_coll;
    struct chr_collector chr_coll;
    struct scalar_collector scalar_coll;
    struct vector_collector vec_coll;
    struct variant_collector variant_coll;
    struct multi_collector multi_coll;
    struct recursive_collector rec_coll;
  } details;
};

struct collector* new_scalar_collector(bool required,
                                       r_obj* ptype,
                                       r_obj* ptype_inner,
                                       r_obj* default_value,
                                       r_obj* transform,
                                       r_obj* na,
                                       bool rowmajor);

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
                                       bool rowmajor);

struct collector* new_variant_collector(bool required,
                                        r_obj* default_value,
                                        r_obj* transform,
                                        r_obj* elt_transform,
                                        bool rowmajor);

struct collector* new_row_collector(bool required,
                                    int n_keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    r_obj* keys,
                                    r_obj* ptype_dummy,
                                    int n_cols,
                                    bool rowmajor);

struct collector* new_sub_collector(int n_keys,
                                    r_obj* coll_locations,
                                    r_obj* col_names,
                                    r_obj* keys,
                                    r_obj* ptype_dummy,
                                    int n_cols,
                                    bool rowmajor);

struct collector* new_df_collector(bool required,
                                   int n_keys,
                                   r_obj* coll_locations,
                                   r_obj* col_names,
                                   r_obj* names_col,
                                   r_obj* keys,
                                   r_obj* ptype_dummy,
                                   int n_cols,
                                   bool rowmajor);

struct collector* new_parser(int n_keys,
                             r_obj* coll_locations,
                             r_obj* col_names,
                             r_obj* names_col,
                             r_obj* keys,
                             r_obj* ptype_dummy,
                             int n_cols,
                             bool rowmajor);

struct collector* new_recursive_collector(void);

void alloc_row_collector(struct collector* v_collector, r_ssize n_rows);
r_ssize get_collector_vec_rows(struct collector* v_collector,
                               r_obj* value,
                               r_ssize* n_rows,
                               struct Path* path,
                               struct Path* nrow_path);
r_obj* get_ptype_row(struct collector* v_collector);

void assign_in_multi_collector(r_obj* x, r_obj* xi, bool unpack, r_obj* ffi_locs);

r_obj* ffi_tibblify(r_obj* data, r_obj* spec, r_obj* path_xptr);

#endif
