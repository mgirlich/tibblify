#include "tibblify.h"
#include "Path.h"
#include "add-value.h"
#include "finalize.h"
#include "conditions.h"

void add_stop_required(struct collector* v_collector, struct Path* path) {
  stop_required(path->data);
}

#define ADD_DEFAULT(CTYPE)                                     \
  ((CTYPE*) v_collector->v_data)[v_collector->current_row] = *((CTYPE*) v_collector->default_value); \
  ++v_collector->current_row;

// TODO use `v_collector->r_default_value`?
#define ADD_DEFAULT_BARRIER(SET)                               \
  r_obj* r_default_value = (r_obj*) v_collector->default_value;\
  SET(v_collector->data, v_collector->current_row, r_default_value);\
  ++v_collector->current_row;

void add_default_lgl(struct collector* v_collector, struct Path* path) {
  ADD_DEFAULT(int);
}

void add_default_int(struct collector* v_collector, struct Path* path) {
  ADD_DEFAULT(int);
}

void add_default_dbl(struct collector* v_collector, struct Path* path) {
  ADD_DEFAULT(int);
}

void add_default_chr(struct collector* v_collector, struct Path* path) {
  ADD_DEFAULT_BARRIER(r_chr_poke);
}

void add_default_scalar(struct collector* v_collector, struct Path* path) {
  r_list_poke(v_collector->data, v_collector->current_row, v_collector->r_default_value);
  ++v_collector->current_row;
}

void children_add_default(struct collector* v_collector, struct Path* path) {
  struct multi_collector* coll = &v_collector->details.multi_coll;
  r_obj* const * v_keys = r_chr_cbegin(coll->keys);

  path_down(path);
  struct collector* v_collectors = coll->collectors;
  for (int key_index = 0; key_index < coll->n_keys; ++key_index, ++v_keys) {
    path_replace_key(path, *v_keys);
    struct collector* cur_coll = &v_collectors[key_index];
    cur_coll->add_default(cur_coll, path);
  }
  path_up(path);
}

void children_add_default_absent(struct collector* v_collector, struct Path* path) {
  struct multi_collector* coll = &v_collector->details.multi_coll;
  r_obj* const * v_keys = r_chr_cbegin(coll->keys);

  path_down(path);
  struct collector* v_collectors = coll->collectors;
  for (int key_index = 0; key_index < coll->n_keys; key_index++, v_keys++) {
    path_replace_key(path, *v_keys);
    struct collector* cur_coll = &v_collectors[key_index];
    cur_coll->add_default_absent(cur_coll, path);
  }
  path_up(path);
}

void add_default_row(struct collector* v_collector, struct Path* path) {
  children_add_default(v_collector, path);
}

void add_default_coll(struct collector* v_collector, struct Path* path) {
  r_list_poke(v_collector->data, v_collector->current_row, v_collector->r_default_value);
  ++v_collector->current_row;
}

void add_default_df(struct collector* v_collector, struct Path* path) {
  r_list_poke(v_collector->data, v_collector->current_row, r_null);
  ++v_collector->current_row;
}

#define ADD_VALUE(CTYPE, NA, EMPTY, CAST)                                     \
  if (value == r_null) {                                       \
    ((CTYPE*) v_collector->v_data)[v_collector->current_row] = NA; \
    ++v_collector->current_row;                                \
    return;                                                    \
  }                                                            \
                                                               \
  r_obj* value_casted = KEEP(vec_cast(value, EMPTY));          \
  r_ssize size = short_vec_size(value_casted);                 \
  if (size != 1) {                                             \
    stop_scalar(size, path->data);                             \
  }                                                            \
                                                               \
  ((CTYPE*) v_collector->v_data)[v_collector->current_row] = CAST(value_casted);\
  ++v_collector->current_row;                                  \
  FREE(1);

void add_value_scalar(struct collector* v_collector, r_obj* value, struct Path* path) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, v_collector->na);
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, v_collector->ptype_inner));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size, path->data);
  }

  r_list_poke(v_collector->data, v_collector->current_row, value_casted);
  ++v_collector->current_row;
  FREE(1);
}

void add_value_lgl(struct collector* v_collector, r_obj* value, struct Path* path) {
  // TODO could use `r_lgl_get(value_casted, 0)`?
  // r_printf("lgl: current row: %d\n", v_collector->current_row);
  ADD_VALUE(int, r_globals.na_lgl, r_globals.empty_lgl, Rf_asLogical);
}

void add_value_int(struct collector* v_collector, r_obj* value, struct Path* path) {
  ADD_VALUE(int, r_globals.na_int, r_globals.empty_int, Rf_asInteger);
}

void add_value_dbl(struct collector* v_collector, r_obj* value, struct Path* path) {
  ADD_VALUE(double, r_globals.na_dbl, r_globals.empty_dbl, Rf_asReal);
}

void add_value_chr(struct collector* v_collector, r_obj* value, struct Path* path) {
  if (value == r_null) {
    r_chr_poke(v_collector->data, v_collector->current_row, r_globals.na_str);
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, r_globals.empty_chr));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size, path->data);
  }

  r_chr_poke(v_collector->data, v_collector->current_row, r_chr_get(value_casted, 0));
  ++v_collector->current_row;
  FREE(1);

  return;
}

r_obj* vec_unchop_value(r_obj* value,
                        enum vector_form input_form,
                        r_obj* ptype,
                        r_obj* na,
                        struct Path* path) {
  // FIXME if `vec_assign()` gets exported this should use
  // `vec_init()` + `vec_assign()`
  r_ssize loc_first_null = -1;
  r_ssize n = r_length(value);
  r_obj* const * v_value = r_list_cbegin(value);

  for (r_ssize i = 0; i < n; ++i, ++v_value) {
    if (*v_value == r_null) {
      loc_first_null = i;
      break;
    }

    if (vec_size(*v_value) != 1) {
      stop_vector_wrong_size_element(path->data, input_form, value);
    }
  }

  if (loc_first_null == -1) {
    return(vec_flatten(value, ptype));
  }

  // Theoretically a shallow duplicate should be more efficient but in
  // benchmarks this didn't seem to be the case...
  r_obj* out_list = KEEP(Rf_shallow_duplicate(value));
  for (r_ssize i = loc_first_null; i < n; ++i, ++v_value) {
    if (*v_value == r_null) {
      r_list_poke(out_list, i, na);
      continue;
    }

    if (vec_size(*v_value) != 1) {
      stop_vector_wrong_size_element(path->data, input_form, value);
    }
  }

  r_obj* out = vec_flatten(out_list, ptype);
  FREE(1);
  return out;
}

void add_value_vec(struct collector* v_collector, r_obj* value, struct Path* path) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
    ++v_collector->current_row;
    return;
  }

  struct vector_collector vec_coll = v_collector->details.vector_coll;
  if (vec_coll.input_form == VECTOR_FORM_vector && vec_coll.vector_allows_empty_list) {
    if (r_length(value) == 0 && r_typeof(value) == R_TYPE_list) {
      r_list_poke(v_collector->data, v_collector->current_row, vec_coll.empty_element);
      ++v_collector->current_row;
      return;
    }
  }

  r_obj* names = r_names(value);
  if (vec_coll.input_form == VECTOR_FORM_scalar_list || vec_coll.input_form == VECTOR_FORM_object) {
    // FIXME should check with `vec_is_list()`?
    if (r_typeof(value) != R_TYPE_list) {
      stop_vector_non_list_element(path->data, vec_coll.input_form, value);
    }

    if (vec_coll.input_form == VECTOR_FORM_object && names == r_null) {
      stop_object_vector_names_is_null(path->data);
    }

    value = vec_unchop_value(value,
                             vec_coll.input_form,
                             v_collector->ptype_inner,
                             v_collector->na,
                             path);
  }
  KEEP(value);

  if (vec_coll.elt_transform != r_null) value = apply_transform(value, vec_coll.elt_transform);
  KEEP(value);

  r_obj* value_prepped = KEEP(v_collector->details.vector_coll.prep_data(value, names));
  r_obj* value_casted = KEEP(vec_cast(value_prepped, v_collector->ptype));

  r_list_poke(v_collector->data, v_collector->current_row, value_casted);
  ++v_collector->current_row;

  FREE(4);
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

void add_value_row(struct collector* v_collector, r_obj* value, struct Path* path) {
  // r_printf("add_value_row()\n");
  struct multi_collector* coll = &v_collector->details.multi_coll;

  if (value == r_null) {
    children_add_default(v_collector, path);
    return;
  }

  const r_ssize n_fields = r_length(value);
  if (n_fields == 0) {
    children_add_default_absent(v_collector, path);
    return;
  }

  r_obj* field_names = r_names(value);
  if (field_names == r_null) {
    stop_names_is_null(path->data);
  }

  // TODO this->update_fields(field_names, n_fields, path);
  match_chr(coll->keys, field_names, coll->p_key_match_ind, n_fields);

  // TODO r_list_cbegin only works if object is a list
  r_obj* const * v_keys = r_chr_cbegin(coll->keys);
  r_obj* const * v_value = r_list_cbegin(value);

  path_down(path);
  struct collector* v_collectors = coll->collectors;
  for (int key_index = 0; key_index < coll->n_keys; key_index++) {
    int loc = coll->p_key_match_ind[key_index];
    r_obj* cur_key = v_keys[key_index];
    path_replace_key(path, cur_key);

    struct collector* cur_coll = &v_collectors[key_index];
    if (loc < 0) {
      cur_coll->add_default_absent(cur_coll, path);
    } else {
      r_obj* cur_value = v_value[loc];

      cur_coll->add_value(cur_coll, cur_value, path);
    }
  }
  path_up(path);
}

void add_value_df(struct collector* v_collector, r_obj* value, struct Path* path) {
  // r_printf("add_value_df() - current row: %d\n", v_collector->current_row);
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
  } else {
    // path.down();
    r_obj* parsed_value = KEEP(parse(v_collector, value, path));
    r_list_poke(v_collector->data, v_collector->current_row, parsed_value);
    FREE(1);
    // path.up();
  }
  ++v_collector->current_row;
}

void add_value_variant(struct collector* v_collector, r_obj* value, struct Path* path) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
    ++v_collector->current_row;
    return;
  }

  struct variant_collector variant_coll = v_collector->details.variant_coll;
  if (variant_coll.elt_transform != r_null) value = apply_transform(value, variant_coll.elt_transform);
  KEEP(value);
  r_list_poke(v_collector->data, v_collector->current_row, value);
  ++v_collector->current_row;
  FREE(1);
}

r_obj* parse(struct collector* v_collector, r_obj* value, struct Path* path) {
  r_ssize n_rows = short_vec_size(value);

  init_row_collector(v_collector, n_rows);

  // struct collector* v_collectors = v_collector->details.multi_coll.collectors;
  // r_printf("# out-cols: %d\n", v_collector->details.multi_coll.n_keys);
  // r_printf("# out-rows: %d\n", r_length(v_collectors[0].data));

  // r_printf("# parse: %d\n", n_rows);
  // path_down(path);
  r_obj* const * v_value = r_list_cbegin(value);
  for (r_ssize i = 0; i < n_rows; ++i) {
    // r_printf("row: %d\n", i);
    path_replace_int(path, i);
    r_obj* const row = v_value[i];
    add_value_row(v_collector, row, path);
  }
  // path_up(path);

  return finalize_row(v_collector);
}
