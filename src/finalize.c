// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "finalize.h"

r_obj* finalize_atomic_scalar(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);
  KEEP(data);
  data = vec_cast(data, v_collector->ptype);

  FREE(1);
  return data;
}

r_obj* finalize_scalar(struct collector* v_collector) {
  r_obj* value = vec_flatten(v_collector->data, v_collector->details.vec_coll.ptype_inner);
  KEEP(value);

  if (v_collector->transform != r_null) value = apply_transform(value, v_collector->transform);
  KEEP(value);
  r_obj* value_cast = KEEP(vec_cast(value, v_collector->ptype));

  FREE(3);
  return value_cast;
}

r_obj* finalize_vec(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);

  r_attrib_poke_class(data, classes_list_of);
  r_attrib_poke(data, syms_ptype, v_collector->details.vec_coll.list_of_ptype);

  return data;
}

r_obj* finalize_variant(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);

  return data;
}

r_obj* finalize_row(struct collector* v_collector) {
  struct multi_collector* multi_coll = &v_collector->details.multi_coll;
  r_ssize n_cols = multi_coll->n_cols;
  r_obj* df = KEEP(r_alloc_list(n_cols));
  r_attrib_poke_names(df, multi_coll->col_names);

  struct collector* v_collectors = multi_coll->collectors;

  for (r_ssize i = 0; i < multi_coll->n_keys; ++i) {
    r_obj* col = KEEP(v_collectors[i].finalize(&v_collectors[i]));
    // TODO must use `coll_locations`
    r_obj* ffi_locs = r_list_get(multi_coll->coll_locations, i);
    r_list_poke(df, r_int_get(ffi_locs, 0), col);
    FREE(1);
  }

  r_init_tibble(df, multi_coll->n_rows);

  FREE(1);
  return df;
}

r_obj* finalize_df(struct collector* v_collector) {
  r_obj* data = v_collector->data;

  r_attrib_poke_class(data, classes_list_of);
  r_attrib_poke(data, syms_ptype, v_collector->ptype);

  return data;
}
