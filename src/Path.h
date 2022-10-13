#ifndef TIBBLIFY_PATH_H
#define TIBBLIFY_PATH_H

#define R_NO_REMAP
#define STRICT_R_HEADERS
#include "tibblify.h"

struct Path {
  r_obj* data;
  int* depth;
  r_obj* path_elts;
};

static inline
void path_down(struct Path* path) {
  ++(*path->depth);
}

static inline
void path_up(struct Path* path) {
  --(*path->depth);
}

static inline
void path_replace_int(struct Path* path, int index) {
  r_obj* ffi_index = KEEP(r_int(index));
  r_list_poke(path->path_elts, *path->depth, ffi_index);
  FREE(1);
}

static inline
void path_replace_key(struct Path* path, r_obj* key) {
  r_obj* ffi_key = KEEP(r_alloc_character(1));
  r_chr_poke(ffi_key, 0, key);
  r_list_poke(path->path_elts, *path->depth, ffi_key);
  FREE(1);
}

#endif
