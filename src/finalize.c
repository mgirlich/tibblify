#include "finalize.h"
#include "tibblify.h"
#include "collector.h"
#include "utils.h"

r_obj* finalize_atomic_scalar(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);
  KEEP(data);

  data = vec_cast(data, v_collector->ptype);
  FREE(1);
  return data;
}

r_obj* finalize_scalar(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  // non-atomic scalars are collected in a list. Therefore, they need to be
  // flattened into a vector
  if (v_collector->rowmajor) {
    data = vec_flatten(v_collector->data, v_collector->details.vec_coll.ptype_inner);
  }
  KEEP(data);

  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);
  KEEP(data);

  r_obj* value_cast = vec_cast(data, v_collector->ptype);
  FREE(2);
  return value_cast;
}

r_obj* finalize_vec(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);
  KEEP(data);

  r_attrib_poke_class(data, classes_list_of);
  r_attrib_poke(data, syms_ptype, v_collector->details.vec_coll.list_of_ptype);
  FREE(1);
  return data;
}

r_obj* finalize_variant(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  if (v_collector->transform != r_null) data = apply_transform(data, v_collector->transform);

  return data;
}

r_obj* finalize_row(struct collector* v_collector) {
  struct multi_collector* p_multi_coll = &v_collector->details.multi_coll;
  r_ssize n_cols = p_multi_coll->n_cols;
  r_obj* df = KEEP(alloc_df(p_multi_coll->n_rows, n_cols, p_multi_coll->col_names));

  struct collector* v_collectors = p_multi_coll->collectors;
  for (r_ssize i = 0; i < p_multi_coll->n_keys; ++i) {
    struct collector* v_coll_i = &v_collectors[i];
    r_obj* col = KEEP(v_coll_i->finalize(v_coll_i));

    r_obj* ffi_locs = r_list_get(p_multi_coll->coll_locations, i);
    assign_in_multi_collector(df, col, v_coll_i->unpack, ffi_locs);
    FREE(1);
  }

  FREE(1);
  return df;
}

r_obj* finalize_df(struct collector* v_collector) {
  r_obj* data = v_collector->data;

  r_attrib_poke_class(data, classes_list_of);
  r_obj* ptype = KEEP(get_ptype_row(v_collector));
  r_attrib_poke(data, syms_ptype, ptype);

  FREE(1);
  return data;
}

r_obj* finalize_recursive(struct collector* v_collector) {
  return v_collector->data;
}
