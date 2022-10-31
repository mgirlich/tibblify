#ifndef TIBBLIFY_PARSE_SPEC_H
#define TIBBLIFY_PARSE_SPEC_H

#include "tibblify.h"

void collector_add_fields(struct collector* p_coll,
                          r_obj* fields,
                          bool vector_allows_empty_list,
                          bool rowmajor);

struct collector* create_parser(r_obj* spec);

#endif
