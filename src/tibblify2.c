// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"

struct r_string_types_struct r_string_types;
struct r_vector_form_struct r_vector_form;

r_obj* ffi_tibblify(r_obj* data, r_obj* spec, r_obj* ffi_path) {
  struct collector* coll_parser = create_parser(spec);
  KEEP(coll_parser->shelter);

  r_obj* depth = KEEP(r_alloc_integer(1));
  r_int_poke(depth, 0, 0);
  r_list_poke(ffi_path, 0, depth);
  r_obj* path_elts = KEEP(r_alloc_list(30));
  r_list_poke(ffi_path, 1, path_elts);

  struct Path path = (struct Path) {
    .data = ffi_path,
    .depth = r_int_begin(r_list_get(ffi_path, 0)),
    .path_elts = r_list_get(ffi_path, 1)
  };

  r_obj* out = parse(coll_parser, data, &path);
  FREE(3);

  return out;
}
