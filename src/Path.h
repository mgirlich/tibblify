#ifndef TIBBLIFY_PATH_H
#define TIBBLIFY_PATH_H

#include <cpp11.hpp>
#include "tibblify.h"

class Path {
private:
  cpp11::writable::list path;
  int depth = 0;
  Path(const Path&);
  Path& operator=(const Path&);

public:
  Path() {
    path = Rf_allocVector(VECSXP, 20);
  }

  ~ Path() {}

  inline void down() {
    // FIXME: fail if diving too deep
    this->depth++;
  }

  inline void up() {
    this->depth--;
  }

  inline void replace(int index) {
    SET_VECTOR_ELT(this->path, this->depth, Rf_ScalarInteger(index));
  }

  inline void replace(const SEXP key) {
    SET_VECTOR_ELT(this->path, this->depth, key);
  }

  inline SEXP data() const {
    cpp11::list path_cpp(path);
    cpp11::writable::list out(this->depth + 1);
    for (int i = 0; i < this->depth + 1; i++) {
      if (TYPEOF(path_cpp[i]) == CHARSXP) {
        out[i] = cpp11::writable::strings({path_cpp[i]});
      } else {
        out[i] = path_cpp[i];
      }
    }
    return out;
  }
};

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
#endif
