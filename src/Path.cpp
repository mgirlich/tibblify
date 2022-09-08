#include <cpp11.hpp>
#include "tibblify.h"
#include "Path.h"

[[cpp11::register]]
SEXP init_tibblify_path() {
  auto path = new Path();
  cpp11::external_pointer<Path> res(path);
  return res;
}

[[cpp11::register]]
SEXP get_path_data(cpp11::external_pointer<Path> path_ptr) {
  return path_ptr->data();
}
