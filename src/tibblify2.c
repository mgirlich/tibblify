// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"

struct r_string_types_struct r_string_types;
struct r_vector_form_struct r_vector_form;

r_obj* ffi_tibblify(r_obj* data, r_obj* spec) {
  struct collector* coll_parser = create_parser(spec);
  KEEP(coll_parser->shelter);
  r_obj* out = parse(coll_parser, data);
  FREE(1);

  return out;
}
