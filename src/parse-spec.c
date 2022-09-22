#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"

struct r_string_types {
  r_obj* sub;
  r_obj* row;
  r_obj* df;
  r_obj* scalar;
  r_obj* vector;
} r_string_types;

struct collector* parse_spec_elt(r_obj* spec_elt, r_obj* keys, int i) {
  r_obj* key = r_chr_get(r_list_get_by_name(spec_elt, "key"), 0);
  r_chr_poke(keys, i, key);

  r_obj* type = r_chr_get(r_list_get_by_name(spec_elt, "type"), 0);

  // if (type == "sub") {
  //   cpp11::list sub_spec = elt["spec"];
  //   auto spec_pair = parse_fields_spec(sub_spec, vector_allows_empty_list, input_form);
  //   col_vec.push_back(Collector_Ptr(new Collector_Same_Key(spec_pair.first, spec_pair.second)));
  //   continue;
  // }

  // r_obj* name = r_list_get_by_name(spec_elt, "name");
  const int col_location = r_int_get(r_list_get_by_name(spec_elt, "location"), 0);
  const bool required = r_lgl_get(r_list_get_by_name(spec_elt, "required"), 0);
  r_obj* default_value = r_list_get_by_name(spec_elt, "fill");

  // struct collector coll;

  // if (type == r_string_types.row) {
  //   r_obj* fields = r_list_get_by_name(spec_elt, "fields");
  //   coll.coll_type = COLLECTOR_TYPE_row;
  //   const r_ssize n_sub_fields = r_length(fields);
  //
  //   struct key_collector_pair sub_spec = parse_fields_spec(fields);
  //   coll.details.row_coll = (struct row_collector) {
  //     .keys = sub_spec.keys,
  //     .collectors = sub_spec.collectors,
  //     .n_keys = n_sub_fields,
  //     .key_match_ind = malloc(n_sub_fields * sizeof(int)),
  //   };
  //
  //   *v_collectors = coll;
  //   ++v_collectors;
  //
  //   // auto spec_pair = parse_fields_spec(fields, vector_allows_empty_list, input_form);
  //   // col_vec.push_back(Collector_Ptr(new Collector_Tibble(spec_pair.first, spec_pair.second, required, location, name)));
  //   continue;
  // // } else if (type == "df") {
  // //   cpp11::list fields = spec_elt["fields"];
  // //   auto spec_pair = parse_fields_spec(fields, vector_allows_empty_list, input_form);
  // //
  // //   cpp11::sexp names_col = spec_elt["names_col"];
  // //   if (names_col != r_null) {
  // //     names_col = cpp11::strings(names_col)[0];
  // //   }
  // //
  // //   col_vec.push_back(
  // //     Collector_Ptr(
  // //       new Collector_List_Of_Tibble(spec_pair.first, spec_pair.second, names_col, required, location, name, input_form)
  // //     )
  // //   );
  // //   continue;
  // }

  // Field_Args field_args = Field_Args(elt["fill"], elt["transform"]);
  //
  // if (type == "unspecified") {
  //   col_vec.push_back(Collector_Ptr(new Collector_List(required, location, name, field_args)));
  //   continue;
  // }
  // if (type == "variant") {
  //   col_vec.push_back(Collector_Ptr(new Collector_List(required, location, name, field_args, elt["elt_transform"])));
  //   continue;
  // }

  r_obj* ptype = r_list_get_by_name(spec_elt, "ptype");
  r_obj* ptype_inner = r_list_get_by_name(spec_elt, "ptype_inner");
  if (type == r_string_types.scalar) {
    return new_scalar_collector(required,
                                col_location,
                                ptype,
                                ptype_inner,
                                default_value);
    // } else if (type == "vector") {
    //   cpp11::r_string input_form = cpp11::strings(elt["input_form"])[0];
    //   Vector_Args vector_args = Vector_Args(
    //     string_to_form_enum(input_form),
    //     vector_allows_empty_list,
    //     elt["names_to"],
    //     elt["values_to"],
    //     elt["na"],
    //     elt["elt_transform"]
    //   );
    //
    //   col_vec.push_back(Collector_Ptr(new Collector_Vector(required, location, name, field_args, vector_args))
    //   );
  } else {
    r_printf(CHAR(type));
    r_printf(CHAR(r_string_types.scalar));
    r_stop_internal("Internal Error: Unsupported type"); // # nocov
  }
}

struct key_collector_pair* parse_fields_spec(r_obj* spec) {
  // bool vector_allows_empty_list,
  // std::string input_form) {
  r_obj* key_coll_pair = KEEP(r_alloc_raw(sizeof(struct key_collector_pair)));
  struct key_collector_pair* v_key_coll_pair = r_raw_begin(key_coll_pair);

  // TODO check that `spec` is a list
  const r_ssize n_fields = r_length(spec);

  r_obj* shelter = KEEP(r_alloc_list(2));

  r_obj* keys = KEEP(r_alloc_character(n_fields));
  r_list_poke(shelter, 0, keys);

  // TODO should be global const
  size_t coll_size = sizeof(struct collector);
  r_obj* collectors = KEEP(r_alloc_raw(coll_size * n_fields));
  r_list_poke(shelter, 1, collectors);

  struct collector* v_collectors = r_raw_begin(collectors);

  v_key_coll_pair->shelter = shelter;
  v_key_coll_pair->keys = keys;
  v_key_coll_pair->v_collectors = v_collectors;
  // std::vector<Collector_Ptr> col_vec;

  r_obj* const * v_spec = r_list_cbegin(spec);

  r_preserve_global(r_string_types.sub = r_str("sub"));
  r_preserve_global(r_string_types.row = r_str("row"));
  r_preserve_global(r_string_types.df = r_str("df"));
  r_preserve_global(r_string_types.scalar = r_str("scalar"));
  r_preserve_global(r_string_types.vector = r_str("vector"));

  for (r_ssize i = 0; i < n_fields; ++i) {
    *v_collectors = *parse_spec_elt(v_spec[i], keys, i);
    ++v_collectors;
  }

  FREE(4);
  return v_key_coll_pair;
}
