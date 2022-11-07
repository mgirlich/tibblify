#ifndef TIBBLIFY_ADD_VALUE_H
#define TIBBLIFY_ADD_VALUE_H

#include "collector.h"
#include "Path.h"
#include "tibblify.h"

void add_stop_required(struct collector* v_collector, struct Path* path);

static inline
void assign_f_absent(struct collector* v_collector, bool required) {
  if (required) {
    v_collector->add_default_absent = &add_stop_required;
  } else {
    v_collector->add_default_absent = v_collector->add_default;
  }
}

void add_default_lgl(struct collector* v_collector, struct Path* path);
void add_default_int(struct collector* v_collector, struct Path* path);
void add_default_dbl(struct collector* v_collector, struct Path* path);
void add_default_chr(struct collector* v_collector, struct Path* path);
void add_default_scalar(struct collector* v_collector, struct Path* path);
void add_default_vector(struct collector* v_collector, struct Path* path);
void add_default_variant(struct collector* v_collector, struct Path* path);
void add_default_row(struct collector* v_collector, struct Path* path);
void add_default_df(struct collector* v_collector, struct Path* path);
void add_default_recursive(struct collector* v_collector, struct Path* path);

void add_value_lgl(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_int(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_dbl(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_chr(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_scalar(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_vector(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_variant(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_row(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_df(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_recursive(struct collector* v_collector, r_obj* value, struct Path* path);

void add_value_lgl_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_int_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_dbl_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_chr_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_scalar_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_vector_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_variant_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_row_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_df_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);
void add_value_recursive_colmajor(struct collector* v_collector, r_obj* value, struct Path* path);

static inline
r_obj* vec_prep_simple(r_obj* value_casted, r_obj* names, r_obj* col_names) {
  return value_casted;
}

static inline
r_obj* vec_prep_values(r_obj* value_casted, r_obj* names, r_obj* col_names) {
  r_obj* df = KEEP(r_alloc_list(1));
  r_attrib_poke_names(df, col_names);
  r_init_tibble(df, short_vec_size(value_casted));

  r_list_poke(df, 0, value_casted);
  FREE(1);
  return df;
}

static inline
r_obj* vec_prep_values_names(r_obj* value_casted, r_obj* names, r_obj* col_names) {
  r_obj* df = KEEP(r_alloc_list(2));
  r_attrib_poke_names(df, col_names);
  r_ssize n = short_vec_size(value_casted);
  r_init_tibble(df, n);

  if (names == r_null) {
    names = KEEP(r_alloc_character(n));
    r_chr_fill(names, r_strs.empty, n);
  } else {
    KEEP(names);
  }

  r_list_poke(df, 0, names);
  r_list_poke(df, 1, value_casted);
  FREE(2);
  return df;
}

r_obj* parse(struct collector* v_collector, r_obj* value, struct Path* v_path);
r_obj* parse_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path);

#endif
