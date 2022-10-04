// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "finalize.h"

r_obj* finalize_scalar(struct collector* v_collector) {
  // r_printf("finalize_scalar()\n");
  r_obj* data = v_collector->data;
  // if (this->transform != r_null) data = apply_transform(data, this->transform);
  KEEP(data);
  data = KEEP(vec_cast(data, v_collector->ptype));

  FREE(2);
  return data;
}

r_obj* finalize_row(struct collector* v_collector) {
  // r_printf("finalize_row()\n");
  r_ssize n_col = v_collector->details.multi_coll.n_keys;
  r_obj* df = KEEP(r_alloc_vector(R_TYPE_list, n_col));
  r_attrib_poke_names(df, v_collector->details.multi_coll.keys);

  struct collector* v_collectors = v_collector->details.multi_coll.collectors;

  for (r_ssize i = 0; i < n_col; ++i) {
    // r_printf("finalize_row() -> finalize\n");
    r_obj* col = v_collectors[i].finalize(&v_collectors[i]);
    // r_printf("finalize_row() -> assign data\n");
    // TODO must use `coll_locations`
    r_list_poke(df, i, col);
    // r_list_poke(df, i, v_collectors[i].data);
  }

  r_init_tibble(df, v_collector->details.multi_coll.n_rows);

  FREE(1);
  return df;
}

r_obj* finalize_df(struct collector* v_collector) {
  // r_printf("finalize_df()\n");

  return v_collector->data;
}
