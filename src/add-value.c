#include "tibblify.h"
#include "add-value.h"
#include "conditions.h"

void add_default_lgl(struct collector* v_collector, const bool check) {
  if (check && v_collector->required) stop_required();

  ((int*) v_collector->v_data)[v_collector->current_row] = *((int*) v_collector->default_value);
  ++v_collector->current_row;
}

void add_default_chr(struct collector* v_collector, const bool check) {
  if (check && v_collector->required) stop_required();

  r_obj* r_default_value = (r_obj*) v_collector->default_value;
  r_chr_poke(v_collector->data, v_collector->current_row, r_default_value);
  ++v_collector->current_row;
}

void children_add_default(struct collector* v_collector, const bool check) {
  struct row_collector* coll = &v_collector->details.row_coll;
  r_obj* const * v_keys = r_chr_cbegin(coll->keys);

  //     path.down();
  for (int key_index = 0; key_index < coll->n_keys; key_index++, v_keys++) {
  //   // path.replace(*v_keys);
    r_obj* r_cur_coll = r_list_get(coll->collectors, key_index);
    struct collector* cur_coll = r_raw_begin(r_cur_coll);
    cur_coll->add_default(cur_coll, check);
  }
  //     path.up();
}

void add_default_row(struct collector* v_collector, const bool check) {
  if (check && v_collector->required) stop_required();

  children_add_default(v_collector, false);
}

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
  }

  r_list_poke(v_collector->data, v_collector->current_row, r_null);
  ++v_collector->current_row;
  FREE(1);

  return;
}

void add_value_lgl(struct collector* v_collector, r_obj* value) {
  // r_printf("add_value_lgl()\n");
  if (value == r_null) {
    ((int*) v_collector->v_data)[v_collector->current_row] = r_globals.na_lgl;
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, r_globals.empty_lgl));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size);
  }

  // TODO could use `r_lgl_get(value_casted, 0)`?
  ((int*) v_collector->v_data)[v_collector->current_row] = Rf_asLogical(value_casted);
  ++v_collector->current_row;

  FREE(1);

  return;
}

void add_value_chr(struct collector* v_collector, r_obj* value) {
  // r_printf("add_value_chr()\n");
  if (value == r_null) {
    r_chr_poke(v_collector->data, v_collector->current_row, r_globals.na_str);
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, r_globals.empty_chr));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size);
  }

  r_chr_poke(v_collector->data, v_collector->current_row, r_chr_get(value_casted, 0));
  ++v_collector->current_row;
  FREE(1);

  return;
}

//   inline void update_order(r_obj* field_names, const int& n_fields) {
//     LOG_DEBUG;
//
//     this->n_fields_prev = n_fields;
//     this->field_names_prev = field_names;
//     this->key_match_ind = match_chr(this->keys, field_names);
//   }


void match_chr(r_obj* needles_sorted,
               r_obj* haystack,
               r_ssize* indices,
               const r_ssize n_haystack) {
  // LOG_DEBUG;

  // CAREFUL: this assumes needles to be sorted!
  r_obj* const * v_needles = r_chr_cbegin(needles_sorted);
  r_obj* const * v_haystack = r_chr_cbegin(haystack);

  const r_ssize n_needles = r_length(needles_sorted);

  int haystack_ind[n_haystack];
  R_orderVector1(haystack_ind, n_haystack, haystack, FALSE, FALSE);

  r_ssize i = 0;
  r_ssize j = 0;
  for (i = 0; (i < n_needles) && (j < n_haystack); ) {
    r_obj* hay = v_haystack[haystack_ind[j]];
    if (*v_needles == hay) {
      indices[i] = haystack_ind[j];
      v_needles++;
      i++; j++;
      continue;
    }

    const char* needle_char = r_str_c_string(*v_needles);
    const char* hay_char = r_str_c_string(hay);
    // needle is too small, so go to next needle
    if (strcmp(needle_char, hay_char) < 0) {
      // LOG_DEBUG << "needle too small";
      // needle not found in haystack
      indices[i] = -1;
      v_needles++; i++;
    } else {
      // LOG_DEBUG << "hay too small";
      j++;
    }
  }

  // mark remaining needles as not found
  for (; i < n_needles; i++) {
    indices[i] = -1;
  }

  return;
}

void add_value_row(struct collector* v_collector, r_obj* value) {
  // r_printf("add_value_row()\n");
  struct row_collector* coll = &v_collector->details.row_coll;

  if (value == r_null) {
    children_add_default(v_collector, false);
    return;
  }

  const r_ssize n_fields = r_length(value);
  if (n_fields == 0) {
    children_add_default(v_collector, true);
    return;
  }

  r_obj* field_names = r_names(value);
  if (field_names == r_null) {
    stop_names_is_null();
  }

  // TODO this->update_fields(field_names, n_fields, path);
  match_chr(coll->keys, field_names, coll->key_match_ind, n_fields);

  // TODO r_list_cbegin only works if object is a list
  r_obj* const * v_keys = r_chr_cbegin(coll->keys);
  r_obj* const * v_value = r_list_cbegin(value);

  // path.down();
  for (int key_index = 0; key_index < coll->n_keys; key_index++) {
    int loc = coll->key_match_ind[key_index];
    // r_obj* cur_key = v_keys[key_index];
    // path.replace(cur_key);

    r_obj* r_cur_coll = r_list_get(coll->collectors, key_index);
    struct collector* cur_coll = r_raw_begin(r_cur_coll);
    if (loc < 0) {
      cur_coll->add_default(cur_coll, true);
    } else {
      r_obj* cur_value = v_value[loc];

      cur_coll->add_value(cur_coll, cur_value);
    }
  }
  // path.up();
}
