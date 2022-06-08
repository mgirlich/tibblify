/* TODOs
 * [ ] heuristic to detect object vs list of object -> appropriate error message
 * [ ] support integer index
 * [ ] add other scalar types: complex, raw
 * [ ] natively support `id` column in `Collector_Tibble`?
 */

#include <cpp11.hpp>
#include <vector>
#include "tibblify.h"
#include "utils.h"
#include "Path.h"

inline void stop_scalar(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_scalar"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_required(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_required"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_duplicate_name(const Path& path, SEXPREC* field_nm) {
  SEXP call = PROTECT(Rf_lang3(Rf_install("stop_duplicate_name"),
                               PROTECT(path.data()),
                               cpp11::as_sexp(cpp11::r_string(field_nm))));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_empty_name(const Path& path, const int& index) {
  SEXP call = PROTECT(Rf_lang3(Rf_install("stop_empty_name"),
                               PROTECT(path.data()),
                               cpp11::as_sexp(index)));
  Rf_eval(call, tibblify_ns_env);
}

inline void stop_names_is_null(const Path& path) {
  SEXP call = PROTECT(Rf_lang2(Rf_install("stop_names_is_null"),
                               PROTECT(path.data())));
  Rf_eval(call, tibblify_ns_env);
}

inline SEXP apply_transform(SEXP value, SEXP fn) {
  // from https://github.com/r-lib/vctrs/blob/9b65e090da2a0f749c433c698a15d4e259422542/src/names.c#L83
  SEXP call = PROTECT(Rf_lang2(syms_transform, syms_value));

  SEXP mask = PROTECT(r_new_environment(R_GlobalEnv));
  Rf_defineVar(syms_transform, fn, mask);
  Rf_defineVar(syms_value, value, mask);
  SEXP out = PROTECT(Rf_eval(call, mask));

  UNPROTECT(3);
  return out;
}


class Collector {
protected:
  bool needs_unprotect = false;
public:
  virtual ~ Collector() {};

  // reserve space and mark as `needs_unprotect`
  virtual inline void init(R_xlen_t& length) = 0;
  // number of columns it expands in the end
  // only really relevant for `Collector_Same_Key`
  virtual inline int size() const = 0;
  // if key is found -> add `object` to internal memory
  virtual inline void add_value(SEXP object, Path& path) = 0;
  // if key is absent -> check if field is required; if not add `default`
  virtual inline void add_default(Path& path) = 0;
  // called for data frame column
  virtual inline void add_default_df() = 0;
  // assign data to input `list` at correct location and update `names`
  virtual inline void assign_data(SEXP list, SEXP names) const = 0;
  virtual inline void unprotect() = 0;
};

using Collector_Ptr = std::unique_ptr<Collector>;


class Collector_Scalar_Base : public Collector {
protected:
  SEXP data;
  const bool required;
  const int col_location;
  const SEXP name;
  const SEXP transform;

public:
  Collector_Scalar_Base(bool& required_, int& col_location_, SEXP name_, SEXP transform_)
    : required(required_)
  , col_location(col_location_)
  , name(name_)
  , transform(transform_)
  { }

  inline void unprotect() {
    if (this->needs_unprotect) {
      UNPROTECT(1);
      this->needs_unprotect = false;
    }
  }

  inline int size() const {
    return 1;
  }
};

class Collector_Scalar : public Collector_Scalar_Base {
protected:
  const SEXP default_value;
  const SEXP ptype;
  int current_row = 0;

public:
  Collector_Scalar(SEXP default_value_, bool required_, SEXP ptype_, int col_location_,
                   SEXP name_, SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(vec_cast(default_value_, ptype_))
  , ptype(ptype_)
  { }

  inline void init(R_xlen_t& length) {
    this->data = PROTECT(Rf_allocVector(VECSXP, length));
    this->current_row = 0;
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform);
    SEXP value_casted = vec_cast(value, ptype);
    R_len_t size = short_vec_size(value_casted);
    if (size == 0) {
      value_casted = this->default_value;
    } else if (size > 1) {
      stop_scalar(path);
    }

    SET_VECTOR_ELT(this->data, this->current_row++, value_casted);
  }

  inline void add_default(Path& path) {
    if (required) stop_required(path);
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void add_default_df() {
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SEXP call = PROTECT(Rf_lang3(Rf_install("vec_flatten"),
                                 this->data,
                                 this->ptype));
    SEXP value = R_tryEval(call, tibblify_ns_env, NULL);

    SET_VECTOR_ELT(list, this->col_location, value);
    SET_STRING_ELT(names, this->col_location, this->name);
    UNPROTECT(1);
  }
};


#define ADD_VALUE(F_SCALAR)                                    \
  if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform); \
  SEXP value_casted = vec_cast(value, this->ptype);            \
  R_len_t size = short_vec_size(value_casted);                 \
  if (size == 0) {                                             \
    *this->data_ptr = this->default_value;                     \
  } else if (size == 1) {                                      \
    *this->data_ptr = F_SCALAR(value_casted);                  \
  } else if (size > 1) {                                       \
    stop_scalar(path);                                         \
  }                                                            \
                                                               \
  ++this->data_ptr;

#define ADD_DEFAULT()                                          \
  if (this->required) stop_required(path);                     \
  *this->data_ptr = this->default_value;                       \
  ++this->data_ptr;

#define ADD_DEFAULT_DF()                                       \
  *this->data_ptr = this->default_value;                       \
  ++this->data_ptr;


class Collector_Scalar_Lgl : public Collector_Scalar_Base {
private:
  const int default_value;
  const SEXP ptype = tibblify_shared_empty_lgl;
  int* data_ptr;

public:
  Collector_Scalar_Lgl(int default_value_, bool required_, int col_location_,
                       SEXP name_, SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(default_value_)
  { }

  inline void init(R_xlen_t& length) {
    this->data = PROTECT(Rf_allocVector(LGLSXP, length));
    this->data_ptr = LOGICAL(this->data);
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    ADD_VALUE(Rf_asLogical);
  }

  inline void add_default(Path& path) {
    ADD_DEFAULT();
  }

  inline void add_default_df() {
    ADD_DEFAULT_DF();
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

class Collector_Scalar_Int : public Collector_Scalar_Base {
private:
  const int default_value;
  const SEXP ptype = tibblify_shared_empty_int;
  int* data_ptr;

public:
  Collector_Scalar_Int(int default_value_, bool required_, int col_location_,
                       SEXP name_, SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(default_value_)
  { }

  inline void init(R_xlen_t& length) {
    this->data = PROTECT(Rf_allocVector(INTSXP, length));
    this->data_ptr = INTEGER(this->data);
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    ADD_VALUE(Rf_asInteger);
  }

  inline void add_default(Path& path) {
    ADD_DEFAULT();
  }

  inline void add_default_df() {
    ADD_DEFAULT_DF();
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

class Collector_Scalar_Dbl : public Collector_Scalar_Base {
private:
  const double default_value;
  const SEXP ptype = tibblify_shared_empty_dbl;
  double* data_ptr;

public:
  Collector_Scalar_Dbl(double default_value_, bool required_, int col_location_,
                       SEXP name_, SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(default_value_)
  { }

  inline void init(R_xlen_t& length) {
    this->data = PROTECT(Rf_allocVector(REALSXP, length));
    this->data_ptr = REAL(this->data);
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    ADD_VALUE(Rf_asReal);
  }

  inline void add_default(Path& path) {
    ADD_DEFAULT();
  }

  inline void add_default_df() {
    ADD_DEFAULT_DF();
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

class Collector_Scalar_Str : public Collector_Scalar_Base {
private:
  const SEXP default_value;
  const SEXP ptype = tibblify_shared_empty_chr;
  SEXP* data_ptr;

public:
  Collector_Scalar_Str(SEXP default_value_, bool required_, int col_location_,
                       SEXP name_, SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(default_value_)
  { }

  void init(R_xlen_t& length) {
    this->data = PROTECT(Rf_allocVector(STRSXP, length));
    this->data_ptr = STRING_PTR(this->data);
    this->needs_unprotect = true;
  }

  void add_value(SEXP value, Path& path) {
    ADD_VALUE(Rf_asChar);
  }

  inline void add_default(Path& path) {
    ADD_DEFAULT();
  }

  inline void add_default_df() {
    ADD_DEFAULT_DF();
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};


class Collector_Vector : public Collector_Scalar_Base {
protected:
  const SEXP default_value;
  const SEXP ptype;
  int current_row = 0;

public:
  Collector_Vector(SEXP default_value_, bool required_, SEXP ptype_, int col_location_,
                   SEXP name_, SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(vec_cast(default_value_, ptype_))
  , ptype(ptype_)
  { }

  inline void init(R_xlen_t& length) {
    this->data = PROTECT(init_list_of(length, this->ptype));
    this->current_row = 0;
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    // TODO use `NULL` if `value` is empty?
    if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform);
    // TODO should be controlled via an argument to `tibblify()`
    if (Rf_length(value) == 0 && TYPEOF(value) == VECSXP) {
      SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
      return;
    }

    SEXP value_casted = vec_cast(value, ptype);
    SET_VECTOR_ELT(this->data, this->current_row++, value_casted);
  }

  inline void add_default(Path& path) {
    if (required) stop_required(path);
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void add_default_df() {
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};


class Collector_List : public Collector_Scalar_Base {
protected:
  const SEXP default_value;
  int current_row = 0;

public:
  Collector_List(SEXP default_value_, bool required_, int col_location_, SEXP name_,
                 SEXP transform_)
    : Collector_Scalar_Base(required_, col_location_, name_, transform_)
  , default_value(default_value_)
  { }

  inline void init(R_xlen_t& length) {
    this->data = PROTECT(Rf_allocVector(VECSXP, length));
    this->current_row = 0;
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform);
    SET_VECTOR_ELT(this->data, this->current_row++, value);
  }

  inline void add_default(Path& path) {
    if (required) stop_required(path);
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void add_default_df() {
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};


class Multi_Collector {
private:
  SEXP field_names_prev = R_NilValue;
  int n_fields_prev = 0;
  const int INDEX_SIZE = 256;
  int *ind = (int *) R_alloc(this->INDEX_SIZE, sizeof(int));
  bool needs_unprotect = false;

  inline bool have_fields_changed(SEXP field_names, const int& n_fields) const {
    if (n_fields != this->n_fields_prev) return true;

    if (n_fields > this->INDEX_SIZE) cpp11::stop("At most 256 fields are supported");
    const SEXP* nms_ptr = STRING_PTR_RO(field_names);
    const SEXP* nms_ptr_prev = STRING_PTR_RO(this->field_names_prev);
    for (int i = 0; i < n_fields; i++, nms_ptr++, nms_ptr_prev++)
      if (*nms_ptr != *nms_ptr_prev) return true;

    return false;
  }

  inline void update_order(SEXP field_names, const int& n_fields) {
    this->n_fields_prev = n_fields;
    this->field_names_prev = field_names;
    R_orderVector1(this->ind, n_fields, field_names, FALSE, FALSE);
  }

  inline void check_names(const SEXP* field_names_ptr, const int n_fields, const Path& path) {
    // this relies on the fields already being in order
    if (n_fields <= 1) return;

    SEXPREC* field_nm = field_names_ptr[this->ind[0]];
    if (field_nm == NA_STRING || field_nm == strings_empty) stop_empty_name(path, this->ind[0]);

    for (int field_index = 1; field_index < n_fields; field_index++) {
      SEXPREC* field_nm_prev = field_nm;
      field_nm = field_names_ptr[this->ind[field_index]];
      if (field_nm == field_nm_prev) stop_duplicate_name(path, field_nm);

      if (field_nm == NA_STRING || field_nm == strings_empty) stop_empty_name(path, this->ind[field_index]);
    }
  }

protected:
  SEXP keys;
  std::vector<Collector_Ptr> collector_vec;
  const int n_keys;

public:
  Multi_Collector(SEXP keys_, std::vector<Collector_Ptr>& collector_vec_)
    : n_keys(Rf_length(keys_))
  {
    int n_keys = Rf_length(keys_);
    R_orderVector1(this->ind, n_keys, keys_, FALSE, FALSE);
    this->n_fields_prev = Rf_length(keys_);
    this->field_names_prev = keys_;

    this->keys = PROTECT(Rf_allocVector(STRSXP, n_keys));
    this->needs_unprotect = true;
    for(int i = 0; i < n_keys; i++) {
      int key_index = this->ind[i];
      SET_STRING_ELT(this->keys, i, STRING_ELT(keys_, key_index));
      this->collector_vec.emplace_back(std::move(collector_vec_[key_index]));
    }
  }

  inline void unprotect() {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).unprotect();
    }
    if (this->needs_unprotect) {
      UNPROTECT(1);
      this->needs_unprotect = false;
    }
  }

  inline void init(R_xlen_t& length) {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).init(length);
    }
  }

  inline void add_value(SEXP object, Path& path) {
    const SEXP* key_names_ptr = STRING_PTR_RO(this->keys);
    const int n_fields = Rf_length(object);

    if (n_fields == 0) {
      path.down();
      for (int key_index = 0; key_index < this->n_keys; key_index++, key_names_ptr++) {
        path.replace(*key_names_ptr);
        (*this->collector_vec[key_index]).add_default(path);
      }
      path.up();
      return;
    }

    SEXP field_names = Rf_getAttrib(object, R_NamesSymbol);
    if (field_names == R_NilValue) stop_names_is_null(path);

    const bool fields_have_changed = this->have_fields_changed(field_names, n_fields);
    const SEXP* field_names_ptr = STRING_PTR_RO(field_names);
    // only update `ind` if necessary as `R_orderVector1()` is pretty slow
    if (fields_have_changed) {
      this->update_order(field_names, n_fields);
      this->check_names(field_names_ptr, n_fields, path);
    }

    // TODO VECTOR_PTR_RO only works if object is a list
    const SEXP* values_ptr = VECTOR_PTR_RO(object);

    // The manual loop is quite a bit faster than the range based loop
    path.down();
    int key_index = 0;
    int field_index = 0;
    for (field_index = 0; (field_index < n_fields) && (key_index < this->n_keys); ) {
      SEXPREC* field_nm = field_names_ptr[this->ind[field_index]];

      if (field_nm == *key_names_ptr) {
        path.replace(*key_names_ptr);
        (*this->collector_vec[key_index]).add_value(values_ptr[this->ind[field_index]], path);
        key_names_ptr++; key_index++;
        field_index++;
        continue;
      }

      const char* key_char = CHAR(*key_names_ptr); // TODO might be worth caching
      const char* field_nm_char = CHAR(field_nm);
      if (strcmp(key_char, field_nm_char) < 0) {
        path.replace(*key_names_ptr);
        (*this->collector_vec[key_index]).add_default(path);
        key_names_ptr++; key_index++;
        continue;
      }

      // field_name does not occur in keys
      // TODO store unused field_name somewhere?
      field_index++;
    }

    for (; key_index < this->n_keys; key_index++) {
      path.replace(*key_names_ptr);
      (*this->collector_vec[key_index]).add_default(path);
      key_names_ptr++;
    }

    path.up();
  }
};


class Collector_Same_Key : public Collector, Multi_Collector {
protected:
  int n_keys;

public:
  Collector_Same_Key(SEXP keys_, std::vector<Collector_Ptr>& collector_vec_)
    : Multi_Collector(keys_, collector_vec_)
  , n_keys(Rf_length(keys_))
  { }

  inline void unprotect() {
    Multi_Collector::unprotect();
  }

  inline int size() const {
    int size = 0;
    for (const Collector_Ptr& collector : this->collector_vec) {
      size += (*collector).size();
    }

    return size;
  }

  inline void init(R_xlen_t& length) {
    Multi_Collector::init(length);
  }

  inline void add_value(SEXP object, Path& path) {
    Multi_Collector::add_value(object, path);
  }

  inline void add_default(Path& path) {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).add_default(path);
    }
  }

  inline void add_default_df() {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).add_default_df();
    }
  }

  inline void assign_data(SEXP list, SEXP names) const {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).assign_data(list, names);
    }
  }
};


class Collector_Tibble : public Collector, Multi_Collector {
private:
  const bool required;
  const int col_location;
  const SEXP name;
  R_xlen_t n_rows;

  inline SEXP get_data() const {
    int size = 0;
    for (const Collector_Ptr& collector : this->collector_vec) {
      size += (*collector).size();
    }
    SEXP df = PROTECT(Rf_allocVector(VECSXP, size));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, size));

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).assign_data(df, names);
    }

    Rf_setAttrib(df, R_NamesSymbol, names);
    set_df_attributes(df, this->n_rows);

    UNPROTECT(2);
    return df;
  }

public:
  Collector_Tibble(SEXP keys_, std::vector<Collector_Ptr>& col_vec_,
                   bool required_, int col_location_, SEXP name_)
    : Multi_Collector(keys_, col_vec_)
  , required(required_)
  , col_location(col_location_)
  , name(name_)
  { }

  ~ Collector_Tibble() {}

  inline void unprotect() {
    Multi_Collector::unprotect();
  }

  inline int size() const {
    return 1;
  }

  inline void init(R_xlen_t& length) {
    this->n_rows = length;
    Multi_Collector::init(length);
  }

  inline void add_value(SEXP object, Path& path) {
    Multi_Collector::add_value(object, path);
  }

  inline void add_default(Path& path) {
    if (required) stop_required(path);
    for (int i = 0; i < this->n_keys; i++) {
      (*this->collector_vec[i]).add_default_df();
    }
  }

  inline void add_default_df() {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).add_default_df();
    }
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->get_data());
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

class Parser_Object_List : Multi_Collector {
private:
  const SEXP names_col;
  const bool has_names_col;

  int get_n_cols() const {
    int n_cols = 0;
    if (this->has_names_col) n_cols = 1;

    for (const Collector_Ptr& collector : this->collector_vec) {
      n_cols += (*collector).size();
    }

    return n_cols;
  }

  inline SEXP get_data(SEXP object_list, R_xlen_t n_rows) {
    const int n_cols = this->get_n_cols();
    SEXP df = PROTECT(Rf_allocVector(VECSXP, n_cols));

    SEXP names = PROTECT(Rf_allocVector(STRSXP, n_cols));
    if (this->has_names_col) {
      SEXP object_list_names = my_vec_names2(object_list);
      SET_VECTOR_ELT(df, 0, object_list_names);

      SET_STRING_ELT(names, 0, this->names_col);
    }

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).assign_data(df, names);
    }

    Rf_setAttrib(df, R_NamesSymbol, names);
    set_df_attributes(df, n_rows);

    UNPROTECT(2);
    Multi_Collector::unprotect();
    return df;
  }

public:
  Parser_Object_List(SEXP keys_, std::vector<Collector_Ptr>& col_vec_, SEXP names_col_ = R_NilValue)
    : Multi_Collector(keys_, col_vec_)
  , names_col(names_col_)
  , has_names_col(!Rf_isNull(names_col_))
  { }

  inline SEXP parse(SEXP object_list, Path& path) {
    R_xlen_t n_rows = short_vec_size(object_list);
    this->init(n_rows);

    if (vec_is_list(object_list)) {
      const SEXP* ptr_row = VECTOR_PTR_RO(object_list);
      for (R_xlen_t row_index = 0; row_index < n_rows; row_index++) {
        path.replace(row_index);
        this->add_value(ptr_row[row_index], path);
      }
    } else {
      SEXP slice_index_int = PROTECT(Rf_allocVector(INTSXP, 1));
      int* slice_index_int_ptr = INTEGER(slice_index_int);

      for (R_xlen_t row_index = 0; row_index < n_rows; row_index++) {
        path.replace(row_index);
        *slice_index_int_ptr = row_index + 1;
        this->add_value(vec_slice_impl(object_list, slice_index_int), path);
      }
      UNPROTECT(1);
    }

    return this->get_data(object_list, n_rows);
  }
};

class Parser_Object : Multi_Collector {
private:
  int get_n_cols() const {
    int n_cols = 0;
    for (const Collector_Ptr& collector : this->collector_vec) {
      n_cols += (*collector).size();
    }

    return n_cols;
  }

  inline SEXP get_data() {
    const int n_cols = this->get_n_cols();
    SEXP df = PROTECT(Rf_allocVector(VECSXP, n_cols));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, n_cols));

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).assign_data(df, names);
    }

    Rf_setAttrib(df, R_NamesSymbol, names);
    set_df_attributes(df, 1);

    UNPROTECT(2);
    Multi_Collector::unprotect();
    return df;
  }

public:
  Parser_Object(SEXP keys_, std::vector<Collector_Ptr>& col_vec_)
    : Multi_Collector(keys_, col_vec_)
  { }

  inline SEXP parse(SEXP object, Path& path) {
    R_xlen_t n_rows = 1;
    this->init(n_rows);
    this->add_value(object, path);

    return this->get_data();
  }
};


class Collector_List_Of_Tibble : public Collector {
private:
  SEXP data;
  const bool required;
  const SEXP name;
  const int col_location;
  const std::unique_ptr<Parser_Object_List> parser_ptr;
  int current_row = 0;

public:
  Collector_List_Of_Tibble(SEXP keys_, std::vector<Collector_Ptr>& col_vec_, SEXP names_col_,
                           bool required_, int& col_location_, SEXP name_)
    : required(required_)
  , name(name_)
  , col_location(col_location_)
  , parser_ptr(std::unique_ptr<Parser_Object_List>(new Parser_Object_List(keys_, col_vec_, names_col_)))
  { }

  inline void unprotect() {
    if (this->needs_unprotect) {
      UNPROTECT(1);
      this->needs_unprotect = false;
    }
  }

  inline void init(R_xlen_t& length) {
    Path path;
    SEXP ptype = (*this->parser_ptr).parse(tibblify_shared_empty_list, path);
    this->data = PROTECT(init_list_of(length, ptype));
    this->current_row = 0;
    this->needs_unprotect = true;
  }

  inline void add_value(SEXP value, Path& path) {
    SET_VECTOR_ELT(this->data, this->current_row++, (*this->parser_ptr).parse(value, path));
  }

  inline void add_default(Path& path) {
    if (required) stop_required(path);
    SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
  }

  inline void add_default_df() {
    SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
  }

  inline int size() const {
    return 1;
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

std::pair<SEXP, std::vector<Collector_Ptr>> parse_fields_spec(cpp11::list spec_list) {
  cpp11::writable::strings keys;
  std::vector<Collector_Ptr> col_vec;

  for (const cpp11::list& elt : spec_list) {
    cpp11::r_string key =  cpp11::strings(elt["key"])[0];
    keys.push_back(key);
    cpp11::r_string type = cpp11::strings(elt["type"])[0];

    if (type == "sub") {
      cpp11::list sub_spec = elt["spec"];
      auto spec_pair = parse_fields_spec(sub_spec);
      col_vec.push_back(std::unique_ptr<Collector_Same_Key>(new Collector_Same_Key(spec_pair.first, spec_pair.second)));
      continue;
    }

    cpp11::r_string name = cpp11::strings(elt["name"])[0];
    int location = cpp11::integers(elt["location"])[0];
    cpp11::r_bool required = cpp11::logicals(elt["required"])[0];

    if (type == "row") {
      cpp11::list fields = elt["fields"];
      auto spec_pair = parse_fields_spec(fields);
      col_vec.push_back(std::unique_ptr<Collector_Tibble>(new Collector_Tibble(spec_pair.first, spec_pair.second, required, location, name)));
      continue;
    } else if (type == "df") {
      cpp11::list fields = elt["fields"];
      auto spec_pair = parse_fields_spec(fields);

      cpp11::sexp names_col = elt["names_col"];
      if (!Rf_isNull(names_col)) {
        names_col = cpp11::strings(names_col)[0];
      }

      col_vec.push_back(
        std::unique_ptr<Collector_List_Of_Tibble>(
          new Collector_List_Of_Tibble(spec_pair.first, spec_pair.second, names_col, required, location, name)
        )
      );
      continue;
    }

    cpp11::sexp transform = elt["transform"];
    cpp11::sexp default_sexp = elt["default_value"];
    if (type == "list") {
      col_vec.push_back(std::unique_ptr<Collector_List>(new Collector_List(default_sexp, required, location, name, transform)));
      continue;
    }

    cpp11::sexp ptype = elt["ptype"];
    if (type == "scalar") {
      if (vec_is(ptype, tibblify_shared_empty_lgl)) {
        cpp11::r_bool default_bool = cpp11::logicals(default_sexp)[0];
        col_vec.push_back(std::unique_ptr<Collector_Scalar_Lgl>(new Collector_Scalar_Lgl(default_bool, required, location, name, transform)));
      } else if (vec_is(ptype, tibblify_shared_empty_int)) {
        int default_int = cpp11::as_integers(default_sexp)[0];
        col_vec.push_back(std::unique_ptr<Collector_Scalar_Int>(new Collector_Scalar_Int(default_int, required, location, name, transform)));
      } else if (vec_is(ptype, tibblify_shared_empty_dbl)) {
        double default_dbl = cpp11::as_doubles(default_sexp)[0];
        col_vec.push_back(std::unique_ptr<Collector_Scalar_Dbl>(new Collector_Scalar_Dbl(default_dbl, required, location, name, transform)));
      } else if (vec_is(ptype, tibblify_shared_empty_chr)) {
        cpp11::sexp default_str = cpp11::strings(default_sexp)[0];
        col_vec.push_back(std::unique_ptr<Collector_Scalar_Str>(new Collector_Scalar_Str(default_str, required, location, name, transform)));
      } else {
        col_vec.push_back(std::unique_ptr<Collector_Scalar>(new Collector_Scalar(default_sexp, required, ptype, location, name, transform)));
      }
    } else if (type == "vector") {
      col_vec.push_back(std::unique_ptr<Collector_Vector>(new Collector_Vector(default_sexp, required, ptype, location, name, transform)));
    } else {
      cpp11::stop("Internal Error: Unsupported type");
    }
  }

  return std::pair<SEXP, std::vector<Collector_Ptr>>({keys, std::move(col_vec)});
}


[[cpp11::register]]
SEXP tibblify_impl(SEXP object_list, SEXP spec) {
  Path path;

  cpp11::list spec_list = spec;
  cpp11::r_string type = cpp11::strings(spec_list["type"])[0];
  auto spec_pair = parse_fields_spec(spec_list["fields"]);
  if (type == "df") {
    cpp11::sexp names_col = spec_list["names_col"];
    if (!Rf_isNull(names_col)) {
      names_col = cpp11::strings(names_col)[0];
    }

    return Parser_Object_List(spec_pair.first, spec_pair.second, names_col).parse(object_list, path);
  } else if (type == "row" || type == "object") {
    // `path.up()` is needed because `parse()` assumes a list of objects and
    // directly uses `path.down()`
    path.up();
    return Parser_Object(spec_pair.first, spec_pair.second).parse(object_list, path);
  } else {
    cpp11::stop("Internal Error: Unexpected type");
  }
}
