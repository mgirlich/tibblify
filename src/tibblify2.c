// #include <plogr.h>
#include "tibblify.h"
#include "collector.h"
#include "utils.h"
#include "parse-spec.h"
#include "add-value.h"

struct r_string_types_struct r_string_types;

r_obj* ffi_tibblify(r_obj* data, r_obj* spec) {
  r_preserve_global(r_string_types.sub = r_str("sub"));
  r_preserve_global(r_string_types.row = r_str("row"));
  r_preserve_global(r_string_types.df = r_str("df"));
  r_preserve_global(r_string_types.scalar = r_str("scalar"));
  r_preserve_global(r_string_types.vector = r_str("vector"));

  r_obj* out = KEEP(parse(create_parser(spec), data));
  FREE(1);

  return out;
}
