#include <cpp11.hpp>
#include "tibblify.h"

class Path {
private:
  SEXP path = PROTECT(Rf_allocVector(VECSXP, 20));
  int depth = 0;
  Path(const Path&);
  Path& operator=(const Path&);

public:
  Path() {}

  ~ Path() {
    UNPROTECT(1);
  }

  inline void down() {
    this->depth++;
  }

  inline void up() {
    this->depth--;
  }

  inline void replace(int index) {
    SET_VECTOR_ELT(this->path, this->depth, Rf_ScalarInteger(index));
  }

  inline void replace(const SEXP* key) {
    SET_VECTOR_ELT(this->path, this->depth, *key);
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
