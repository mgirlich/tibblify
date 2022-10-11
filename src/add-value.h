#ifndef TIBBLIFY_ADD_VALUE_H
#define TIBBLIFY_ADD_VALUE_H

#include "tibblify.h"
#include "collector.h"

void add_stop_required(struct collector* v_collector);

void add_default_lgl(struct collector* v_collector);
void add_default_int(struct collector* v_collector);
void add_default_dbl(struct collector* v_collector);
void add_default_chr(struct collector* v_collector);
void add_default_scalar(struct collector* v_collector);
void add_default_row(struct collector* v_collector);
void add_default_df(struct collector* v_collector);
void add_default_coll(struct collector* v_collector);

void add_value_scalar(struct collector* v_collector, r_obj* value);
void add_value_lgl(struct collector* v_collector, r_obj* value);
void add_value_int(struct collector* v_collector, r_obj* value);
void add_value_dbl(struct collector* v_collector, r_obj* value);
void add_value_chr(struct collector* v_collector, r_obj* value);
void add_value_vec(struct collector* v_collector, r_obj* value);
void add_value_variant(struct collector* v_collector, r_obj* value);
void add_value_row(struct collector* v_collector, r_obj* value);
void add_value_df(struct collector* v_collector, r_obj* value);

static inline
r_obj* vec_prep_simple(r_obj* value_casted, r_obj* names) {
  return value_casted;
}

static inline
r_obj* vec_prep_values(r_obj* value_casted, r_obj* names) {
  r_obj* df = KEEP(r_alloc_vector(R_TYPE_list, 1));
  r_init_tibble(df, short_vec_size(value_casted));

  r_list_poke(df, 0, value_casted);
  FREE(1);
  return df;
}

static inline
r_obj* vec_prep_values_names(r_obj* value_casted, r_obj* names) {
  r_obj* df = KEEP(r_alloc_vector(R_TYPE_list, 2));
  r_init_tibble(df, short_vec_size(value_casted));

  if (names == r_null) {
    // TODO
    // names = na_chr(n)
  }
  KEEP(names);

  r_list_poke(df, 0, names);
  r_list_poke(df, 1, value_casted);
  FREE(2);
  return df;
}
r_obj* parse(struct collector* v_collector, r_obj* value);

#endif
