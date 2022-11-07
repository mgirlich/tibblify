#ifndef TIBBLIFY_FINALIZE_H
#define TIBBLIFY_FINALIZE_H

#include "collector.h"
#include "tibblify.h"

r_obj* finalize_atomic_scalar(struct collector* v_collector);
r_obj* finalize_scalar(struct collector* v_collector);
r_obj* finalize_vec(struct collector* v_collector);
r_obj* finalize_variant(struct collector* v_collector);
r_obj* finalize_row(struct collector* v_collector);
r_obj* finalize_sub(struct collector* v_collector);
r_obj* finalize_df(struct collector* v_collector);
r_obj* finalize_recursive(struct collector* v_collector);

#endif
