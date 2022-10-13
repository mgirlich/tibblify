#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"

struct collector* parse_spec_elt(r_obj* spec_elt,
                                 bool vector_allows_empty_list) {
  r_obj* type = r_chr_get(r_list_get_by_name(spec_elt, "type"), 0);

  // if (type == "sub") {
  //   cpp11::list sub_spec = elt["spec"];
  //   auto spec_pair = parse_fields_spec(sub_spec, vector_allows_empty_list, input_form);
  //   col_vec.push_back(Collector_Ptr(new Collector_Same_Key(spec_pair.first, spec_pair.second)));
  //   continue;
  // }

  const bool required = r_lgl_get(r_list_get_by_name(spec_elt, "required"), 0);

  if (type == r_string_types.row || type == r_string_types.df) {
    r_obj* sub_spec = r_list_get_by_name(spec_elt, "fields");
    r_obj* coll_locations = r_list_get_by_name(spec_elt, "coll_locations");
    r_obj* col_names = r_list_get_by_name(spec_elt, "col_names");

    r_obj* key_coll_pair = KEEP(r_alloc_raw(sizeof(struct key_collector_pair)));
    struct key_collector_pair* v_key_coll_pair = r_raw_begin(key_coll_pair);
    *v_key_coll_pair = *parse_fields_spec(sub_spec, vector_allows_empty_list);
    KEEP(v_key_coll_pair->shelter);
    struct collector* p_collector;

    if (type == r_string_types.row) {
      p_collector = new_row_collector(required,
                                      v_key_coll_pair->keys,
                                      coll_locations,
                                      col_names,
                                      v_key_coll_pair->v_collectors);


    } else {
      // TODO add `names_col`
      // if (names_col != r_null) {
      //   names_col = cpp11::strings(names_col)[0];
      // }
      p_collector = new_df_collector(required,
                                     v_key_coll_pair->keys,
                                     coll_locations,
                                     col_names,
                                     v_key_coll_pair->v_collectors);
    }

    FREE(2);
    return p_collector;
  }

  r_obj* default_value = r_list_get_by_name(spec_elt, "fill");
  r_obj* transform = r_list_get_by_name(spec_elt, "transform");

  if (type == r_string_types.unspecified) {
    return new_variant_collector(required,
                                 default_value,
                                 transform,
                                 r_null);
  }
  if (type == r_string_types.variant) {
    r_obj* elt_transform = r_list_get_by_name(spec_elt, "elt_transform");
    return new_variant_collector(required,
                                 default_value,
                                 transform,
                                 elt_transform);
  }

  r_obj* ptype = r_list_get_by_name(spec_elt, "ptype");
  r_obj* ptype_inner = r_list_get_by_name(spec_elt, "ptype_inner");
  if (type == r_string_types.scalar) {
    return new_scalar_collector(required,
                                ptype,
                                ptype_inner,
                                default_value,
                                transform);
  } else if (type == r_string_types.vector) {
    r_obj* input_form = r_chr_get(r_list_get_by_name(spec_elt, "input_form"), 0);

    return new_vector_collector(required,
                                ptype,
                                ptype_inner,
                                default_value,
                                transform,
                                input_form,
                                vector_allows_empty_list,
                                r_list_get_by_name(spec_elt, "names_to"),
                                r_list_get_by_name(spec_elt, "values_to"),
                                r_list_get_by_name(spec_elt, "na"),
                                r_list_get_by_name(spec_elt, "elt_transform"));
  } else {
    r_printf(CHAR(type));
    r_printf(CHAR(r_string_types.scalar));
    r_stop_internal("Internal Error: Unsupported type"); // # nocov
  }
}

struct key_collector_pair* parse_fields_spec(r_obj* spec,
                                             bool vector_allows_empty_list) {
  r_obj* key_coll_pair = KEEP(r_alloc_raw(sizeof(struct key_collector_pair)));
  struct key_collector_pair* v_key_coll_pair = r_raw_begin(key_coll_pair);

  // TODO check that `spec` is a list
  const r_ssize n_fields = r_length(spec);

  r_obj* shelter = KEEP(r_alloc_list(2));
  r_obj* keys = KEEP(r_alloc_character(n_fields));
  size_t coll_size = sizeof(struct collector);
  r_obj* collectors = KEEP(r_alloc_raw(coll_size * n_fields));
  r_list_poke(shelter, 1, collectors);

  struct collector* v_collectors = r_raw_begin(collectors);

  v_key_coll_pair->shelter = shelter;
  v_key_coll_pair->keys = keys;
  v_key_coll_pair->v_collectors = v_collectors;

  r_obj* const * v_spec = r_list_cbegin(spec);


  for (r_ssize i = 0; i < n_fields; ++i, ++v_collectors) {
    *v_collectors = *parse_spec_elt(v_spec[i], vector_allows_empty_list);

    r_obj* key = r_chr_get(r_list_get_by_name(v_spec[i], "key"), 0);
    r_chr_poke(keys, i, key);
  }

  FREE(4);
  return v_key_coll_pair;
}

struct collector* create_parser(r_obj* spec) {
  // r_printf("============= CREATE PARSER =============\n");
  // r_printf("------------- parse fields -------------\n");
  r_obj* key_coll_pair = KEEP(r_alloc_raw(sizeof(struct key_collector_pair)));
  struct key_collector_pair* v_key_coll_pair = r_raw_begin(key_coll_pair);
  r_obj* fields = r_list_get_by_name(spec, "fields");
  bool vector_allows_empty_list = r_lgl_get(r_list_get_by_name(spec, "vector_allows_empty_list"), 0);
  *v_key_coll_pair = *parse_fields_spec(fields, vector_allows_empty_list);
  KEEP(v_key_coll_pair->shelter);


  // r_printf("============= add locations and names =============\n");
  r_obj* coll_locations = r_list_get_by_name(spec, "coll_locations");
  r_obj* col_names = r_list_get_by_name(spec, "col_names");

  // TODO make this a bit clearer
  // `tspec_df()` basically is a row collector without a key
  // would make more sense if it would not have `required`
  struct collector* p_collector = new_row_collector(false,
                                                    v_key_coll_pair->keys,
                                                    coll_locations,
                                                    col_names,
                                                    v_key_coll_pair->v_collectors);

  FREE(2);
  return p_collector;
}
