// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "finalize.h"

r_obj* finalize_atomic_scalar(struct collector* v_collector) {
  // r_printf("finalize_scalar()\n");
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);
  KEEP(data);
  data = vec_cast(data, v_collector->ptype);

  FREE(1);
  return data;
}

r_obj* finalize_scalar(struct collector* v_collector) {
  r_obj* value = vec_flatten(v_collector->data, v_collector->ptype_inner);
  KEEP(value);

  if (v_collector->transform != r_null) value = apply_transform(value, v_collector->transform);
  KEEP(value);
  r_obj* value_cast = KEEP(vec_cast(value, v_collector->ptype));

  FREE(3);
  return value;
}

r_obj* finalize_vec(struct collector* v_collector) {
  // r_printf("finalize_df()\n");
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);

  r_attrib_poke_class(data, classes_list_of);
  r_attrib_poke(data, syms_ptype, v_collector->details.vector_coll.list_of_ptype);

  return data;
}

r_obj* finalize_row(struct collector* v_collector) {
  // r_printf("finalize_row()\n");
  r_ssize n_col = v_collector->details.multi_coll.n_keys;
  r_obj* df = KEEP(r_alloc_list(n_col));
  r_attrib_poke_names(df, v_collector->details.multi_coll.keys);

  struct collector* v_collectors = v_collector->details.multi_coll.collectors;

  for (r_ssize i = 0; i < n_col; ++i) {
    // r_printf("finalize_row() -> finalize\n");
    r_obj* col = KEEP(v_collectors[i].finalize(&v_collectors[i]));
    // r_printf("finalize_row() -> assign data\n");
    // TODO must use `coll_locations`
    r_list_poke(df, i, col);
    FREE(1);
  }

  r_init_tibble(df, v_collector->details.multi_coll.n_rows);

  FREE(1);
  return df;
}

r_obj* finalize_variant(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);

  return data;
}

r_obj* finalize_df(struct collector* v_collector) {
  r_obj* data = v_collector->data;

  r_attrib_poke_class(data, classes_list_of);
  // r_attrib_poke(data, syms_ptype, v_collector->details.vector_coll.list_of_ptype);

  return data;
}
