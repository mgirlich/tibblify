#ifndef TIBBLIFY_PARSE_SPEC_H
#define TIBBLIFY_PARSE_SPEC_H

#include "tibblify.h"

struct key_collector_pair {
  r_obj* shelter;
  r_obj* keys;
  struct collector* v_collectors;
};

struct key_collector_pair* parse_fields_spec(r_obj* spec);

#endif
