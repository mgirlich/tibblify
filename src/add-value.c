#include "tibblify.h"
#include "add-value.h"
#include "conditions.h"

void add_value_scalar(struct collector* v_collector, r_obj* value) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, v_collector->ptype_inner));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size);
    // stop_scalar(path, size);
  }

  r_list_poke(v_collector->data, v_collector->current_row, r_null);
  ++v_collector->current_row;
  FREE(1);

  return;
}

void add_value_lgl(struct collector* v_collector, r_obj* value) {
  struct scalar_lgl_collector* coll = &v_collector->details.scalar_lgl_coll;
  if (value == r_null) {
    *(coll->v_data) = r_globals.na_lgl;
    ++coll->v_data;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, r_globals.empty_lgl));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size);
    // stop_scalar(path, size);
  }

  // TODO could use `r_lgl_get(value_casted, 0)`?
  *coll->v_data = Rf_asLogical(value_casted);
  ++coll->v_data;

  FREE(1);

  return;
}

void add_value_chr(struct collector* v_collector, r_obj* value) {
  if (value == r_null) {
    r_chr_poke(v_collector->data, v_collector->current_row, r_globals.na_str);
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, r_globals.empty_chr));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size);
    // stop_scalar(path, size);
  }

  r_chr_poke(v_collector->data, v_collector->current_row, r_chr_get(value_casted, 0));
  ++v_collector->current_row;
  FREE(1);

  return;
}
