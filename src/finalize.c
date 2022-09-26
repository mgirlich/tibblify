// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "finalize.h"

void finalize_scalar(struct collector* v_collector) {
  r_obj* data = v_collector->data;
  // if (this->transform != r_null) data = apply_transform(data, this->transform);
  KEEP(data);
  data = KEEP(vec_cast(data, v_collector->ptype));

  v_collector->data = data;
  r_list_poke(v_collector->shelter, 0, data);

  FREE(2);
  return;
}

void finalize_row(struct collector* v_collector) {
  r_attrib_poke_names(v_collector->data, v_collector->details.row_coll.keys);

  r_ssize n_col = v_collector->details.row_coll.n_keys;
  struct collector* v_collectors = v_collector->details.row_coll.collectors;

  for (r_ssize i = 0; i < n_col; ++i) {
    v_collectors[i].finalize(&v_collectors[i]);
    r_list_poke(v_collector->data, i, v_collectors[i].data);
  }
}

void finalize_df(struct collector* v_collector) {
}
