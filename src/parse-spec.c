#include "parse-spec.h"
#include "collector.h"
#include "utils.h"
#include "tibblify.h"

struct collector* parse_spec_elt(r_obj* spec_elt,
                                 bool vector_allows_empty_list,
                                 bool rowmajor) {
  r_obj* type = r_chr_get(r_list_get_by_name(spec_elt, "type"), 0);

  if (type == r_string_types.sub) {
    r_obj* ffi_fields_spec = r_list_get_by_name(spec_elt, "fields");
    r_obj* coll_locations = r_list_get_by_name(spec_elt, "coll_locations");
    r_obj* col_names = r_list_get_by_name(spec_elt, "col_names");
    r_obj* keys = r_list_get_by_name(spec_elt, "keys");
    r_obj* ptype_dummy = r_list_get_by_name(spec_elt, "ptype_dummy");
    int n_cols = r_int_get(r_list_get_by_name(spec_elt, "n_cols"), 0);
    int n_fields = r_length(ffi_fields_spec);

    struct collector*p_collector = new_sub_collector(n_fields,
                                                     coll_locations,
                                                     col_names,
                                                     keys,
                                                     ptype_dummy,
                                                     n_cols,
                                                     rowmajor);

    KEEP(p_collector->shelter);
    collector_add_fields(p_collector, ffi_fields_spec, vector_allows_empty_list, rowmajor);

    FREE(1);
    return p_collector;
  }

  const bool required = r_lgl_get(r_list_get_by_name(spec_elt, "required"), 0);

  if (type == r_string_types.row || type == r_string_types.df) {
    r_obj* ffi_fields_spec = r_list_get_by_name(spec_elt, "fields");
    r_obj* coll_locations = r_list_get_by_name(spec_elt, "coll_locations");
    r_obj* col_names = r_list_get_by_name(spec_elt, "col_names");
    r_obj* keys = r_list_get_by_name(spec_elt, "keys");
    r_obj* ptype_dummy = r_list_get_by_name(spec_elt, "ptype_dummy");
    int n_cols = r_int_get(r_list_get_by_name(spec_elt, "n_cols"), 0);

    int n_fields = r_length(ffi_fields_spec);
    struct collector* p_collector;
    if (type == r_string_types.row) {
      p_collector = new_row_collector(required,
                                      n_fields,
                                      coll_locations,
                                      col_names,
                                      keys,
                                      ptype_dummy,
                                      n_cols,
                                      rowmajor);


    } else {
      r_obj* names_col = r_list_get_by_name(spec_elt, "names_col");
      if (names_col != r_null) {
        names_col = r_chr_get(names_col, 0);
      }
      p_collector = new_df_collector(required,
                                     n_fields,
                                     coll_locations,
                                     col_names,
                                     names_col,
                                     keys,
                                     ptype_dummy,
                                     n_cols,
                                     rowmajor);
    }

    KEEP(p_collector->shelter);
    collector_add_fields(p_collector, ffi_fields_spec, vector_allows_empty_list, rowmajor);

    FREE(1);
    return p_collector;
  }

  r_obj* default_value = r_list_get_by_name(spec_elt, "fill");
  r_obj* transform = r_list_get_by_name(spec_elt, "transform");

  if (type == r_string_types.unspecified) {
    return new_variant_collector(required,
                                 default_value,
                                 transform,
                                 r_null,
                                 rowmajor);
  }
  if (type == r_string_types.variant) {
    r_obj* elt_transform = r_list_get_by_name(spec_elt, "elt_transform");
    return new_variant_collector(required,
                                 default_value,
                                 transform,
                                 elt_transform,
                                 rowmajor);
  }

  r_obj* ptype = r_list_get_by_name(spec_elt, "ptype");
  r_obj* ptype_inner = r_list_get_by_name(spec_elt, "ptype_inner");
  if (type == r_string_types.scalar) {
    r_obj* na = r_list_get_by_name(spec_elt, "na");
    return new_scalar_collector(required,
                                ptype,
                                ptype_inner,
                                default_value,
                                transform,
                                na,
                                rowmajor);
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
                                r_list_get_by_name(spec_elt, "elt_transform"),
                                r_list_get_by_name(spec_elt, "col_names"),
                                r_list_get_by_name(spec_elt, "list_of_ptype"),
                                rowmajor);
  } else {
    r_printf(CHAR(type));
    r_printf(CHAR(r_string_types.scalar));
    r_stop_internal("Internal Error: Unsupported type"); // # nocov
  }
}

void collector_add_fields(struct collector* p_coll,
                          r_obj* fields,
                          bool vector_allows_empty_list,
                          bool rowmajor) {
  struct multi_collector* p_multi_coll = &p_coll->details.multi_coll;
  r_obj* const * v_spec = r_list_cbegin(fields);
  int n_fields = r_length(fields);

  for (r_ssize i = 0; i < n_fields; ++i) {
    struct collector* coll_i = parse_spec_elt(v_spec[i], vector_allows_empty_list, rowmajor);
    r_list_poke(p_coll->shelter, 5 + i, coll_i->shelter);
    p_multi_coll->collectors[i] = *coll_i;
  }
}

struct collector* create_parser(r_obj* spec) {
  r_obj* fields = r_list_get_by_name(spec, "fields");
  int n_fields = r_length(fields);

  r_obj* coll_locations = r_list_get_by_name(spec, "coll_locations");
  r_obj* col_names = r_list_get_by_name(spec, "col_names");
  r_obj* keys = r_list_get_by_name(spec, "keys");
  r_obj* ptype_dummy = r_list_get_by_name(spec, "ptype_dummy");
  int n_cols = r_int_get(r_list_get_by_name(spec, "n_cols"), 0);
  bool rowmajor = r_lgl_get(r_list_get_by_name(spec, "rowmajor"), 0);

  r_obj* type = r_chr_get(r_list_get_by_name(spec, "type"), 0);
  r_obj* names_col;
  if (type == strings_df) {
    names_col = r_list_get_by_name(spec, "names_col");
  } else {
    names_col = r_null;
  }

  struct collector* p_parser = new_parser(n_fields,
                                          coll_locations,
                                          col_names,
                                          names_col,
                                          keys,
                                          ptype_dummy,
                                          n_cols,
                                          rowmajor);
  KEEP(p_parser->shelter);

  bool vector_allows_empty_list = r_lgl_get(r_list_get_by_name(spec, "vector_allows_empty_list"), 0);
  collector_add_fields(p_parser, fields, vector_allows_empty_list, rowmajor);

  FREE(1);
  return p_parser;
}
