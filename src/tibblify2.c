// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"
#include "finalize.h"

struct r_string_input_form_struct r_string_input_form;
struct r_string_types_struct r_string_types;
struct r_vector_form_struct r_vector_form;

r_obj* ffi_tibblify(r_obj* data, r_obj* spec, r_obj* ffi_path) {
  struct collector* coll_parser = create_parser(spec);
  KEEP(coll_parser->shelter);

  r_obj* depth = KEEP(r_alloc_integer(1));
  r_int_poke(depth, 0, -1);
  r_list_poke(ffi_path, 0, depth);
  r_obj* path_elts = KEEP(r_alloc_list(30));
  r_list_poke(ffi_path, 1, path_elts);

  struct Path path = (struct Path) {
    .data = ffi_path,
    .depth = r_int_begin(depth),
    .path_elts = path_elts
  };

  r_obj* type = r_chr_get(r_list_get_by_name(spec, "type"), 0);
  r_obj* out;

  if (coll_parser->details.multi_coll.rowmajor) {
    if (type == strings_df) {
      // r_obj* names_col = r_list_get_by_name(spec, "names_col");
      out = parse(coll_parser, data, &path);
      // } else (type == strings_object) {
    } else {
      alloc_row_collector(coll_parser, 1);
      add_value_row(coll_parser, data, &path);

      out = finalize_row(coll_parser);
    }
  } else {
    out = parse_colmajor(coll_parser, data, &path);
  }

  FREE(3);
  // return r_null;

  return out;
}
