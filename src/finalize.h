#ifndef TIBBLIFY_FINALIZE_H
#define TIBBLIFY_FINALIZE_H

#include "tibblify.h"

r_obj* finalize_scalar(struct collector* v_collector);
r_obj* finalize_row(struct collector* v_collector);
r_obj* finalize_df(struct collector* v_collector);

#endif
