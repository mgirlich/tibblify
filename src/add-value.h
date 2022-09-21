#ifndef TIBBLIFY_ADD_VALUE_H
#define TIBBLIFY_ADD_VALUE_H

#include "tibblify.h"
#include "collector.h"

void add_value_scalar(struct collector* v_collector, r_obj* value);
void add_value_lgl(struct collector* v_collector, r_obj* value);
void add_value_chr(struct collector* v_collector, r_obj* value);

#endif
