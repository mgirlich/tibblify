#include "add-value.h"
#include "conditions.h"
#include "finalize.h"
#include "Path.h"
#include "utils.h"
#include "tibblify.h"

void add_stop_required(struct collector* v_collector, struct Path* v_path) {
  stop_required(v_path->data);
}

#define ADD_DEFAULT(COLL)                                                      \
  *v_collector->details.COLL.v_data = v_collector->details.COLL.default_value; \
  ++v_collector->details.COLL.v_data;

#define ADD_DEFAULT_BARRIER(COLL, SET)                             \
  r_obj* default_value = v_collector->details.COLL.default_value;  \
  SET(v_collector->data, v_collector->current_row, default_value); \
  ++v_collector->current_row;

void add_default_lgl(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT(lgl_coll);
}

void add_default_int(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT(int_coll);
}

void add_default_dbl(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT(dbl_coll);
}

void add_default_chr(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT_BARRIER(chr_coll, r_chr_poke);
}

void add_default_scalar(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT_BARRIER(scalar_coll, r_list_poke);
}

void add_default_vector(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT_BARRIER(vec_coll, r_list_poke);
}

void add_default_variant(struct collector* v_collector, struct Path* v_path) {
  ADD_DEFAULT_BARRIER(variant_coll, r_list_poke);
}

#define CHILDREN_ADD_DEFAULT(F_DEFAULT)                                       \
  struct multi_collector* coll = &v_collector->details.multi_coll;            \
  struct collector* v_collectors = coll->collectors;                          \
  r_obj* const * v_keys = r_chr_cbegin(coll->keys);                           \
                                                                              \
  path_down(v_path);                                                          \
  for (int key_index = 0; key_index < coll->n_keys; ++key_index, ++v_keys) {  \
    path_replace_key(v_path, *v_keys);                                        \
    struct collector* cur_coll = &v_collectors[key_index];                    \
    cur_coll->F_DEFAULT(cur_coll, v_path);                                    \
  }                                                                           \
  path_up(v_path);

void children_add_default(struct collector* v_collector, struct Path* v_path) {
  CHILDREN_ADD_DEFAULT(add_default);
}

void children_add_default_absent(struct collector* v_collector, struct Path* v_path) {
  CHILDREN_ADD_DEFAULT(add_default_absent);
}

void add_default_row(struct collector* v_collector, struct Path* v_path) {
  CHILDREN_ADD_DEFAULT(add_default);
}

void add_default_df(struct collector* v_collector, struct Path* v_path) {
  // `df` have no default value. Use `NULL` instead
  r_list_poke(v_collector->data, v_collector->current_row, r_null);
  ++v_collector->current_row;
}

void add_default_recursive(struct collector* v_collector, struct Path* v_path) {
  // TODO
  // `df` have no default value. Use `NULL` instead
  r_list_poke(v_collector->data, v_collector->current_row, r_null);
  ++v_collector->current_row;
}

#define ADD_VALUE(COLL, NA, EMPTY, CAST)                       \
  if (value == r_null) {                                       \
    *v_collector->details.COLL.v_data = NA;                    \
    ++v_collector->details.COLL.v_data;                        \
    return;                                                    \
  }                                                            \
                                                               \
  r_obj* value_casted = KEEP(vec_cast(value, EMPTY));          \
  r_ssize size = short_vec_size(value_casted);                 \
  if (size != 1) {                                             \
    stop_scalar(size, v_path->data);                            \
  }                                                            \
                                                               \
  *v_collector->details.COLL.v_data = CAST(value_casted);      \
  ++v_collector->details.COLL.v_data;                          \
  FREE(1);

#define ADD_VALUE_BARRIER(SET, NA, PTYPE, GET)                 \
  if (value == r_null) {                                       \
    SET(v_collector->data, v_collector->current_row, NA);      \
    ++v_collector->current_row;                                \
    return;                                                    \
  }                                                            \
                                                               \
  r_obj* value_casted = KEEP(vec_cast(value, PTYPE));          \
  r_ssize size = short_vec_size(value_casted);                 \
  if (size != 1) {                                             \
    stop_scalar(size, v_path->data);                           \
  }                                                            \
                                                               \
  SET(v_collector->data, v_collector->current_row, GET(value_casted, 0));\
  ++v_collector->current_row;                                  \
  FREE(1);

void add_value_lgl(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE(lgl_coll, r_globals.na_lgl, r_globals.empty_lgl, Rf_asLogical);
}

void add_value_int(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE(int_coll, r_globals.na_int, r_globals.empty_int, Rf_asInteger);
}

void add_value_dbl(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE(dbl_coll, r_globals.na_dbl, r_globals.empty_dbl, Rf_asReal);
}

void add_value_chr(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE_BARRIER(r_chr_poke, r_globals.na_str, r_globals.empty_chr, r_chr_get);
}

void add_value_scalar(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  // FIXME if `vec_assign()` gets exported this should use
  // `vec_init()` + `vec_assign()`
  if (value == r_null) {
    r_obj* na = v_collector->details.scalar_coll.na;
    r_list_poke(v_collector->data, v_collector->current_row, na);
    ++v_collector->current_row;
    return;
  }

  r_obj* value_casted = KEEP(vec_cast(value, v_collector->details.scalar_coll.ptype_inner));
  r_ssize size = short_vec_size(value_casted);
  if (size != 1) {
    stop_scalar(size, v_path->data);
  }

  r_list_poke(v_collector->data, v_collector->current_row, value_casted);
  ++v_collector->current_row;
  FREE(1);
}

// Unlike in the rowmajor case here the `data` field is overwritten and therefore
// must be protected in the shelter.
// For scalars the `data` field is not allocated to avoid unnecessary memory
// consumption.
#define ADD_VALUE_COLMAJOR(PTYPE)                              \
  v_collector->data = KEEP(vec_cast(value, PTYPE));            \
  r_list_poke(v_collector->shelter, 0, v_collector->data);     \
  FREE(1);

void add_value_lgl_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE_COLMAJOR(r_globals.empty_lgl);
}

void add_value_int_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE_COLMAJOR(r_globals.empty_int);
}

void add_value_dbl_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE_COLMAJOR(r_globals.empty_dbl);
}

void add_value_chr_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE_COLMAJOR(r_globals.empty_chr);
}

void add_value_scalar_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  ADD_VALUE_COLMAJOR(v_collector->details.scalar_coll.ptype_inner);
}

r_obj* list_unchop_value(r_obj* value,
                        enum vector_form input_form,
                        r_obj* ptype,
                        r_obj* na,
                        struct Path* v_path) {
  // FIXME if `vec_assign()` gets exported this should use
  // `vec_init()` + `vec_assign()`
  r_ssize n = r_length(value);
  r_obj* const * v_value = r_list_cbegin(value);

  // If there is no `NULL` value (i.e. `loc_first_null` = -1) then there is no
  // need to copy `value`.
  r_ssize loc_first_null = -1;
  for (r_ssize i = 0; i < n; ++i, ++v_value) {
    if (*v_value == r_null) {
      loc_first_null = i;
      break;
    }

    if (vec_size(*v_value) != 1) {
      stop_vector_wrong_size_element(v_path->data, input_form, value);
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
      stop_vector_wrong_size_element(v_path->data, input_form, value);
    }
  }

  r_obj* out = vec_flatten(out_list, ptype);
  FREE(1);
  return out;
}

void add_value_vector(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
    ++v_collector->current_row;
    return;
  }

  struct vector_collector* v_vec_coll = &v_collector->details.vec_coll;
  if (v_vec_coll->input_form == VECTOR_FORM_vector && v_vec_coll->vector_allows_empty_list) {
    if (r_length(value) == 0 && r_typeof(value) == R_TYPE_list) {
      r_list_poke(v_collector->data, v_collector->current_row, v_collector->ptype);
      ++v_collector->current_row;
      return;
    }
  }

  r_obj* names = r_names(value);
  if (v_vec_coll->input_form == VECTOR_FORM_scalar_list || v_vec_coll->input_form == VECTOR_FORM_object) {
    // FIXME should check with `vec_is_list()`?
    if (r_typeof(value) != R_TYPE_list) {
      stop_vector_non_list_element(v_path->data, v_vec_coll->input_form, value);
    }

    if (v_vec_coll->input_form == VECTOR_FORM_object && names == r_null) {
      stop_object_vector_names_is_null(v_path->data);
    }

    value = list_unchop_value(value,
                              v_vec_coll->input_form,
                              v_vec_coll->ptype_inner,
                              v_vec_coll->na,
                              v_path);
  }
  KEEP(value);

  if (v_vec_coll->elt_transform != r_null) value = apply_transform(value, v_vec_coll->elt_transform);
  KEEP(value);

  r_obj* value_casted = KEEP(vec_cast(value, v_collector->ptype));
  r_obj* value_prepped = KEEP(v_vec_coll->prep_data(value_casted, names, v_vec_coll->col_names));

  r_list_poke(v_collector->data, v_collector->current_row, value_prepped);
  ++v_collector->current_row;

  FREE(4);
}

void add_value_vector_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  check_list(value, v_path);

  r_obj* const * v_value = r_list_cbegin(value);
  r_ssize n_value = short_vec_size(value);
  for (r_ssize row = 0; row < n_value; ++row) {
    add_value_vector(v_collector, v_value[row], v_path);
  }
}

void add_value_variant(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
    ++v_collector->current_row;
    return;
  }

  struct variant_collector* variant_coll = &v_collector->details.variant_coll;
  if (variant_coll->elt_transform != r_null) value = apply_transform(value, variant_coll->elt_transform);
  KEEP(value);

  r_list_poke(v_collector->data, v_collector->current_row, value);
  ++v_collector->current_row;

  FREE(1);
}

void add_value_variant_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  check_list(value, v_path);

  r_obj* const * v_value = r_list_cbegin(value);
  r_ssize n_value = short_vec_size(value);
  for (r_ssize row = 0; row < n_value; ++row) {
    add_value_variant(v_collector, v_value[row], v_path);
  }
}

void update_fields(struct collector* v_collector,
                   r_obj* field_names,
                   const int n_fields,
                   struct Path* v_path) {
  struct multi_collector* v_multi_coll = &v_collector->details.multi_coll;
  bool fields_unchanged = chr_equal(field_names, v_multi_coll->field_names_prev);
  // only update `ind` if necessary as `R_orderVector1()` is pretty slow
  if (fields_unchanged) {
    return;
  }

  v_multi_coll->field_names_prev = field_names;
  match_chr(v_multi_coll->keys,
            field_names,
            v_multi_coll->p_key_match_ind,
            r_length(field_names));

  R_orderVector1(v_multi_coll->field_order_ind, n_fields, field_names, FALSE, FALSE);
  check_names_unique(field_names, v_multi_coll->field_order_ind, n_fields, v_path);
}

void add_value_row(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  if (value == r_null) {
    children_add_default(v_collector, v_path);
    return;
  }

  check_list(value, v_path);

  const r_ssize n_fields = r_length(value);
  if (n_fields == 0) {
    children_add_default_absent(v_collector, v_path);
    return;
  }

  r_obj* field_names = check_names_not_null(value, v_path);
  update_fields(v_collector, field_names, n_fields, v_path);

  struct multi_collector* v_multi_coll = &v_collector->details.multi_coll;
  r_obj* const * v_keys = r_chr_cbegin(v_multi_coll->keys);
  r_obj* const * v_value = r_list_cbegin(value);

  path_down(v_path);
  struct collector* v_collectors = v_multi_coll->collectors;
  for (int key_index = 0; key_index < v_multi_coll->n_keys; ++key_index) {
    int loc = v_multi_coll->p_key_match_ind[key_index];
    r_obj* cur_key = v_keys[key_index];
    path_replace_key(v_path, cur_key);

    struct collector* v_cur_coll = &v_collectors[key_index];
    if (loc < 0) {
      path_up(v_path);
      v_cur_coll->add_default_absent(v_cur_coll, v_path);
      path_down(v_path);
    } else {
      r_obj* cur_value = v_value[loc];
      v_cur_coll->add_value(v_cur_coll, cur_value, v_path);
    }
  }
  path_up(v_path);
}

void add_value_row_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  r_obj* field_names = check_names_not_null(value, v_path);
  r_ssize n_fields = r_length(value);
  update_fields(v_collector, field_names, n_fields, v_path);

  struct multi_collector* v_multi_coll = &v_collector->details.multi_coll;
  r_obj* const * v_keys = r_chr_cbegin(v_multi_coll->keys);
  r_obj* const * v_value = r_list_cbegin(value);

  path_down(v_path);
  struct collector* v_collectors = v_multi_coll->collectors;
  for (int key_index = 0; key_index < v_multi_coll->n_keys; ++key_index) {
    int loc = v_multi_coll->p_key_match_ind[key_index];
    r_obj* cur_key = v_keys[key_index];
    path_replace_key(v_path, cur_key);

    struct collector* v_cur_coll = &v_collectors[key_index];
    if (loc < 0) {
      r_stop_internal("Field is absent in colmajor.");
    } else {
      r_obj* cur_value = v_value[loc];
      v_cur_coll->add_value_colmajor(v_cur_coll, cur_value, v_path);
    }
  }
  path_up(v_path);

}

void add_value_df(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  if (value == r_null) {
    r_list_poke(v_collector->data, v_collector->current_row, r_null);
  } else {
    r_obj* parsed_value = KEEP(parse(v_collector, value, v_path));
    r_list_poke(v_collector->data, v_collector->current_row, parsed_value);
    FREE(1);
  }
  ++v_collector->current_row;
}

void add_value_df_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  check_list(value, v_path);

  r_obj* const * v_value = r_list_cbegin(value);
  r_ssize n_value = short_vec_size(value);
  path_down(v_path);
  for (r_ssize row = 0; row < n_value; ++row) {
    path_replace_int(v_path, row);
    r_obj* row_value = v_value[row];

    r_obj* parsed_row;
    if (row_value == r_null) {
      parsed_row = KEEP(r_null);
    } else {
      parsed_row = KEEP(parse_colmajor(v_collector, v_value[row], v_path));
    }

    r_list_poke(v_collector->data, v_collector->current_row, parsed_row);
    FREE(1);
    ++v_collector->current_row;
  }
  path_up(v_path);
}

void add_value_recursive(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  r_obj* data;
  if (value == r_null) {
    data = r_null;
  } else {
    struct collector* parent_coll = v_collector->details.rec_coll.v_parent;
    struct collector* p_parser = parent_coll->copy(parent_coll);
    KEEP(p_parser->shelter);

    data = parse(p_parser, value, v_path);
    FREE(1);
  }
  r_list_poke(v_collector->data, v_collector->current_row, data);
  ++v_collector->current_row;
}

void add_value_recursive_colmajor(struct collector* v_collector, r_obj* value, struct Path* v_path) {
  check_list(value, v_path);

  r_obj* const * v_value = r_list_cbegin(value);
  r_ssize n_value = short_vec_size(value);
  for (r_ssize row = 0; row < n_value; ++row) {
    r_obj* row_value = v_value[row];

    r_obj* parsed_row;
    if (row_value == r_null) {
      parsed_row = KEEP(r_null);
    } else {
      struct collector* parent_coll = v_collector->details.rec_coll.v_parent;
      struct collector* p_parser = parent_coll->copy(parent_coll);
      KEEP(p_parser->shelter);

      parsed_row = parse_colmajor(p_parser, v_value[row], v_path);
    }
    KEEP(parsed_row);

    r_list_poke(v_collector->data, v_collector->current_row, parsed_row);
    FREE(2);
    ++v_collector->current_row;
  }
}

r_obj* parse(struct collector* v_collector,
             r_obj* value,
             struct Path* v_path) {
  r_ssize n_rows = short_vec_size(value);
  alloc_row_collector(v_collector, n_rows);

  if (is_data_frame(value)) {
    add_value_row_colmajor(v_collector, value, v_path);
  } else {
    check_list(value, v_path);

    path_down(v_path);
    r_obj* const * v_value = r_list_cbegin(value);
    for (r_ssize i = 0; i < n_rows; ++i) {
      path_replace_int(v_path, i);
      r_obj* const row = v_value[i];
      add_value_row(v_collector, row, v_path);
    }
    path_up(v_path);
  }

  r_obj* out = finalize_row(v_collector);

  if (v_collector->details.multi_coll.names_col != r_null) {
    r_list_poke(out, 0, names2(value));
  }

  return out;
}

r_obj* parse_colmajor(struct collector* v_collector,
                      r_obj* value,
                      struct Path* v_path) {
  r_obj* ffi_nrow_path = KEEP(r_alloc_list(2));
  struct Path nrow_path = (struct Path) {
    .data = ffi_nrow_path,
  };
  r_ssize n_rows = -1;

  get_collector_vec_rows(v_collector,
                         value,
                         &n_rows,
                         v_path,
                         &nrow_path);

  if (n_rows == -1) {
    // TODO this should probably be an internal error
    r_abort("Could not determine number of rows.");
  }

  alloc_row_collector(v_collector, n_rows);

  add_value_row_colmajor(v_collector, value, v_path);

  r_obj* out = finalize_row(v_collector);

  FREE(1);
  return out;
}
