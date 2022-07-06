/* TODOs
 * [ ] heuristic to detect object vs list of object -> appropriate error message
 * [ ] add other scalar types: complex, raw
 */

#include <cpp11.hpp>
#include <vector>
#include "tibblify.h"
#include "utils.h"
#include "Path.h"
#include "conditions.h"

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

inline SEXP vec_flatten(SEXP value, SEXP ptype) {
  SEXP call = PROTECT(Rf_lang3(syms_vec_flatten,
                               value,
                               ptype));
  SEXP out = Rf_eval(call, tibblify_ns_env);
  UNPROTECT(1);
  return(out);
}

class Collector {
public:
  virtual ~ Collector() {};

  // reserve space
  virtual void init(R_xlen_t& length) = 0;
  // number of columns it expands in the end
  // only really relevant for `Collector_Same_Key`
  virtual int size() const = 0;
  // if key is found -> add `object` to internal memory
  virtual void add_value(SEXP object, Path& path) = 0;
  // if key is absent -> check if field is required; if not add `default`
  virtual void add_default(bool check, Path& path) = 0;
  // assign data to input `list` at correct location and update `names`
  virtual void assign_data(SEXP list, SEXP names) const = 0;
};

using Collector_Ptr = std::unique_ptr<Collector>;


class Collector_Base : public Collector {
protected:
  const bool required;
  const int col_location;
  const SEXP name;
  const SEXP transform;
  const SEXP default_value;
  const SEXP ptype;
  const SEXP ptype_inner;

  int current_row = 0;
  cpp11::writable::list data;

public:
  Collector_Base(bool& required_, int& col_location_, SEXP name_, const Field_Args& field_args)
    : required(required_)
  , col_location(col_location_)
  , name(name_)
  , transform(field_args.transform)
  , default_value(field_args.default_sexp)
  , ptype(field_args.ptype)
  , ptype_inner(field_args.ptype_inner)
  { }

  inline void init(R_xlen_t& length) {
    this->data = Rf_allocVector(VECSXP, length);
    this->current_row = 0;
  }

  inline int size() const {
    return 1;
  }

  inline void add_default(bool check, Path& path) {
    if (check && required) stop_required(path);
    SET_VECTOR_ELT(this->data, this->current_row++, this->default_value);
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SET_VECTOR_ELT(list, this->col_location, this->data);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

class Collector_Scalar : public Collector_Base {
private:
  const SEXP na;

public:
  Collector_Scalar(bool required_, int col_location_, SEXP name_, Field_Args& field_args, SEXP na_)
    : Collector_Base(required_, col_location_, name_, field_args)
  , na(na_)
  { }

  inline void add_value(SEXP value, Path& path) {
    if (Rf_isNull(value)) {
      SET_VECTOR_ELT(this->data, this->current_row++, this->na);
      return;
    }

    SEXP value_casted = PROTECT(vec_cast(value, this->ptype_inner));
    R_len_t size = short_vec_size(value_casted);
    if (size != 1) {
      stop_scalar(path);
    }

    SET_VECTOR_ELT(this->data, this->current_row++, value_casted);
    UNPROTECT(1);
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SEXP value = PROTECT(vec_flatten(this->data, this->ptype_inner));

    if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform);
    SEXP value_cast = PROTECT(vec_cast(PROTECT(value), this->ptype));

    SET_VECTOR_ELT(list, this->col_location, value_cast);
    SET_STRING_ELT(names, this->col_location, this->name);
    UNPROTECT(3);
  }
};

template <typename CPP11_TYPE>
SEXP r_alloc_vector(R_xlen_t& length);

template <>
SEXP r_alloc_vector<cpp11::r_bool>(R_xlen_t& length) {
  return(Rf_allocVector(LGLSXP, length));
}

template <>
SEXP r_alloc_vector<int>(R_xlen_t& length) {
  return(Rf_allocVector(INTSXP, length));
}

template <>
SEXP r_alloc_vector<double>(R_xlen_t& length) {
  return(Rf_allocVector(REALSXP, length));
}

template <>
SEXP r_alloc_vector<cpp11::r_string>(R_xlen_t& length) {
  return(Rf_allocVector(STRSXP, length));
}

template <typename T, typename CPP11_TYPE>
T* r_vector_ptr(SEXP data);

template <>
int* r_vector_ptr<int, cpp11::r_bool>(SEXP data) {
  return(LOGICAL(data));
}

template <>
int* r_vector_ptr<int, int>(SEXP data) {
  return(INTEGER(data));
}

template <>
double* r_vector_ptr<double, double>(SEXP data) {
  return(REAL(data));
}

template <>
SEXP* r_vector_ptr<SEXP, cpp11::r_string>(SEXP data) {
  return(STRING_PTR(data));
}

template <typename T, typename CPP11_TYPE>
T r_vector_cast(SEXP data);

template <>
int r_vector_cast<int, cpp11::r_bool>(SEXP data) {
  return(Rf_asLogical(data));
}

template <>
int r_vector_cast<int, int>(SEXP data) {
  return(Rf_asInteger(data));
};

template <>
double r_vector_cast<double, double>(SEXP data) {
  return(Rf_asReal(data));
}

template <>
SEXP r_vector_cast<SEXP, cpp11::r_string>(SEXP data) {
  return(Rf_asChar(data));
}

template <typename T, typename CPP11_TYPE>
class Collector_Scalar2 : public Collector_Base {
private:
  const T default_value;
  const T na = cpp11::na<CPP11_TYPE>();
  cpp11::sexp data;
  T* data_ptr;

  T convert_default(cpp11::sexp default_sexp) {
    return(cpp11::r_vector<CPP11_TYPE>(default_sexp)[0]);
  }

public:
  Collector_Scalar2(bool required_, int col_location_, SEXP name_, Field_Args& field_args)
    : Collector_Base(required_, col_location_, name_, field_args)
  , default_value(convert_default(field_args.default_sexp))
  { }

  inline void init(R_xlen_t& length) {
    this->data = r_alloc_vector<CPP11_TYPE>(length);
    this->data_ptr = r_vector_ptr<T, CPP11_TYPE>(this->data);
  }

  inline void add_value(SEXP value, Path& path) {
    if (Rf_isNull(value)) {
      *this->data_ptr = this->na;
      ++this->data_ptr;
      return;
    }

    SEXP value_casted = PROTECT(vec_cast(value, this->ptype_inner));
    R_len_t size = short_vec_size(value_casted);
    if (size != 1) {
      stop_scalar(path);
    }

    *this->data_ptr = r_vector_cast<T, CPP11_TYPE>(value_casted);
    ++this->data_ptr;
    UNPROTECT(1);
  }

  inline void add_default(bool check, Path& path) {
    if (check && this->required) stop_required(path);
    *this->data_ptr = this->default_value;
    ++this->data_ptr;
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SEXP data = this->data;
    if (!Rf_isNull(this->transform)) data = apply_transform(data, this->transform);

    SEXP data_cast = PROTECT(vec_cast(PROTECT(data), this->ptype));
    SET_VECTOR_ELT(list, this->col_location, data_cast);
    UNPROTECT(2);
    SET_STRING_ELT(names, this->col_location, this->name);
  }
};

class Collector_Vector : public Collector_Base {
private:
  const vector_input_form input_form;
  const bool uses_names_col;
  const bool uses_values_col;
  const SEXP output_col_names;
  const bool vector_allows_empty_list;
  const SEXP na;

  SEXP get_output_col_names(SEXP names_to_, SEXP values_to_) {
    if (Rf_isNull(values_to_)) {
      return(NULL);
    }

    if (Rf_isNull(names_to_)) {
      return(values_to_);
    } else {
      cpp11::writable::strings col_names(2);
      col_names[0] = cpp11::strings(names_to_)[0];
      col_names[1] = cpp11::strings(values_to_)[0];
      return(col_names);
    }
  }

  cpp11::writable::list init_out_df(R_xlen_t n_rows) {
    return(init_df(n_rows, this->output_col_names));
  }

  SEXP unchop_value(SEXP value, Path& path) {
    // FIXME if `vec_assign()` gets exported this should use
    // `vec_init()` + `vec_assign()`
    R_xlen_t n = Rf_length(value);
    const SEXP* ptr_row = VECTOR_PTR_RO(value);
    cpp11::writable::list out_list(n);
    for (R_xlen_t i = 0; i < n; i++, ptr_row++) {
      if (Rf_isNull(*ptr_row)) {
        out_list[i] = this->na;
        continue;
      }

      if (vec_size(*ptr_row) != 1) {
        stop_vector_wrong_size_element(path, this->input_form);
      }

      out_list[i] = *ptr_row;
    }

    return(vec_flatten(out_list, this->ptype_inner));
  }

public:
  Collector_Vector(bool required_, int col_location_, SEXP name_, Field_Args& field_args, Vector_Args vector_args)
    : Collector_Base(required_, col_location_, name_, field_args)
  , input_form(vector_args.input_form)
  , uses_names_col(!Rf_isNull(vector_args.names_to))
  , uses_values_col(!Rf_isNull(vector_args.values_to))
  , output_col_names(get_output_col_names(vector_args.names_to, vector_args.values_to))
  , vector_allows_empty_list(vector_args.vector_allows_empty_list)
  , na(vector_args.na)
  { }

  inline void init(R_xlen_t& length) {
    Collector_Base::init(length);

    if (this->uses_values_col) {
      auto ptype_df = init_out_df(0);
      if (this->uses_names_col) {
        ptype_df[0] = tibblify_shared_empty_chr;
        ptype_df[1] = this->ptype;
      } else {
        ptype_df[0] = this->ptype;
      }
      set_list_of_attributes(this->data, ptype_df);
    } else {
      set_list_of_attributes(this->data, this->ptype);
    }
  }

  inline void add_value(SEXP value, Path& path) {
    if (Rf_isNull(value)) {
      SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
      return;
    }

    if (this->input_form == vector_input_form::vector && this->vector_allows_empty_list) {
      if (Rf_length(value) == 0 && TYPEOF(value) == VECSXP) {
        // TODO this should probably be `vec_init(this->ptype, 0)`
        SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
        return;
      }
    }

    SEXP names;
    if (this->uses_names_col || this->input_form == vector_input_form::object) {
      names = Rf_getAttrib(value, R_NamesSymbol);
    }

    if (this->input_form == vector_input_form::scalar_list || this->input_form == vector_input_form::object) {
      // FIXME should check with `vec_is_list()`
      if (TYPEOF(value) != VECSXP) {
        stop_vector_non_list_element(path, this->input_form);
      }

      if (this->input_form == vector_input_form::object) {
        if (Rf_isNull(names)) {
          stop_object_vector_names_is_null(path);
        }
      }

      value = unchop_value(value, path);
    }

    if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform);
    SEXP value_casted = PROTECT(vec_cast(PROTECT(value), ptype));

    if (this->uses_values_col) {
      R_len_t size = short_vec_size(value_casted);
      cpp11::writable::list df = init_out_df(size);

      if (this->uses_names_col) {
        // this can only be if `input_form == object` so no need to check
        if (Rf_isNull(names)) {
          // TODO unclear what to do in such a case
          auto names2 = cpp11::writable::strings(size);
          for (int i = 0; i < size; i++) {
            names2[i] = cpp11::na<cpp11::r_string>();
          }
          df[0] = names2;
        } else {
          df[0] = names;
        }
        df[1] = value_casted;
      } else {
        df[0] = value_casted;
      }

      SET_VECTOR_ELT(this->data, this->current_row++, df);
    } else {
      SET_VECTOR_ELT(this->data, this->current_row++, value_casted);
    }
    UNPROTECT(2);
  }
};


class Collector_List : public Collector_Base {
public:
  Collector_List(bool required_, int col_location_, SEXP name_, Field_Args& field_args)
    : Collector_Base(required_, col_location_, name_, field_args)
  { }

  inline void add_value(SEXP value, Path& path) {
    if (Rf_isNull(value)) {
      SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
      return;
    }

    if (!Rf_isNull(this->transform)) value = apply_transform(value, this->transform);
    SET_VECTOR_ELT(this->data, this->current_row++, value);
  }
};


class Multi_Collector {
private:
  cpp11::strings field_names_prev;
  int n_fields_prev = 0;
  static const int INDEX_SIZE = 256;
  int ind[INDEX_SIZE];

  inline bool have_fields_changed(SEXP field_names, const int& n_fields) const {
    if (n_fields != this->n_fields_prev) return true;

    if (n_fields >= INDEX_SIZE) cpp11::stop("At most 256 fields are supported");
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
  cpp11::writable::strings keys;
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

    this->keys = Rf_allocVector(STRSXP, n_keys);
    for(int i = 0; i < n_keys; i++) {
      int key_index = this->ind[i];
      SET_STRING_ELT(this->keys, i, STRING_ELT(keys_, key_index));
      this->collector_vec.emplace_back(std::move(collector_vec_[key_index]));
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
        (*this->collector_vec[key_index]).add_default(true, path);
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
        (*this->collector_vec[key_index]).add_default(true, path);
        key_names_ptr++; key_index++;
        continue;
      }

      // field_name does not occur in keys
      // TODO store unused field_name somewhere?
      field_index++;
    }

    for (; key_index < this->n_keys; key_index++) {
      path.replace(*key_names_ptr);
      (*this->collector_vec[key_index]).add_default(true, path);
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

  inline void add_default(bool check, Path& path) {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).add_default(check, path);
    }
  }

  inline void assign_data(SEXP list, SEXP names) const {
    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).assign_data(list, names);
    }
  }
};

inline SEXP collector_vec_to_df(const std::vector<Collector_Ptr>& collector_vec,
                                R_xlen_t n_rows,
                                int n_extra_cols) {
  int n_cols = n_extra_cols;
  for (const Collector_Ptr& collector : collector_vec) {
    n_cols += (*collector).size();
  }

  SEXP df = PROTECT(Rf_allocVector(VECSXP, n_cols));
  SEXP names = PROTECT(Rf_allocVector(STRSXP, n_cols));

  for (const Collector_Ptr& collector : collector_vec) {
    (*collector).assign_data(df, names);
  }
  set_df_attributes(df, names, n_rows);

  UNPROTECT(2);
  return df;
}



class Collector_Tibble : public Collector_Base, Multi_Collector {
private:
  R_xlen_t n_rows;

public:
  Collector_Tibble(SEXP keys_, std::vector<Collector_Ptr>& col_vec_,
                   bool required_, int col_location_, SEXP name_)
    : Collector_Base(required_, col_location_, name_, Field_Args())
  , Multi_Collector(keys_, col_vec_)
  { }

  inline void init(R_xlen_t& length) {
    this->n_rows = length;
    Multi_Collector::init(length);
  }

  inline void add_value(SEXP object, Path& path) {
    Multi_Collector::add_value(object, path);
  }

  inline void add_default(bool check, Path& path) {
    if (required) stop_required(path);
    for (int i = 0; i < this->n_keys; i++) {
      (*this->collector_vec[i]).add_default(check, path);
    }
  }

  inline void assign_data(SEXP list, SEXP names) const {
    SEXP data = PROTECT(collector_vec_to_df(std::move(this->collector_vec), this->n_rows, 0));

    SET_VECTOR_ELT(list, this->col_location, data);
    SET_STRING_ELT(names, this->col_location, this->name);
    UNPROTECT(1);
  }
};

class Parser_Object_List : Multi_Collector {
private:
  const SEXP names_col;
  const bool has_names_col;

  inline SEXP get_data(SEXP object_list, R_xlen_t n_rows) {
    int n_extra_cols = this->has_names_col ? 1 : 0;

    SEXP out = PROTECT(collector_vec_to_df(std::move(this->collector_vec), n_rows, n_extra_cols));
    SEXP names = Rf_getAttrib(out, R_NamesSymbol);

    if (this->has_names_col) {
      SET_VECTOR_ELT(out, 0, my_vec_names2(object_list));
      SET_STRING_ELT(names, 0, this->names_col);
    }

    UNPROTECT(1);
    return(out);
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

    if (Rf_inherits(object_list, "data.frame")) {
      SEXP slice_index_int = PROTECT(Rf_allocVector(INTSXP, 1));
      int* slice_index_int_ptr = INTEGER(slice_index_int);

      for (R_xlen_t row_index = 0; row_index < n_rows; row_index++) {
        path.replace(row_index);
        *slice_index_int_ptr = row_index + 1;
        this->add_value(PROTECT(vec_slice_impl2(object_list, slice_index_int)), path);
        UNPROTECT(1);
      }
      UNPROTECT(1);
    } else if (vec_is_list(object_list)) {
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
        this->add_value(PROTECT(vec_slice_impl(object_list, slice_index_int)), path);
        UNPROTECT(1);
      }
      UNPROTECT(1);
    }

    return this->get_data(object_list, n_rows);
  }
};

class Parser_Object : Multi_Collector {
public:
  Parser_Object(SEXP keys_, std::vector<Collector_Ptr>& col_vec_)
    : Multi_Collector(keys_, col_vec_)
  { }

  inline SEXP parse(SEXP object, Path& path) {
    R_xlen_t n_rows = 1;
    this->init(n_rows);
    this->add_value(object, path);

    SEXP out = collector_vec_to_df(std::move(this->collector_vec), n_rows, 0);
    return(out);
  }
};


class Collector_List_Of_Tibble : public Collector_Base {
private:
  const std::unique_ptr<Parser_Object_List> parser_ptr;

public:
  Collector_List_Of_Tibble(SEXP keys_, std::vector<Collector_Ptr>& col_vec_, SEXP names_col_,
                           bool required_, int& col_location_, SEXP name_)
    : Collector_Base(required_, col_location_, name_,  Field_Args())
  , parser_ptr(std::unique_ptr<Parser_Object_List>(new Parser_Object_List(keys_, col_vec_, names_col_)))
  { }

  inline void init(R_xlen_t& length) {
    Collector_Base::init(length);
    Path path;
    SEXP ptype = (*this->parser_ptr).parse(tibblify_shared_empty_list, path);
    set_list_of_attributes(this->data, ptype);
  }

  inline void add_value(SEXP value, Path& path) {
    if (Rf_isNull(value)) {
      SET_VECTOR_ELT(this->data, this->current_row++, R_NilValue);
    } else {
      SET_VECTOR_ELT(this->data, this->current_row++, (*this->parser_ptr).parse(value, path));
    }
  }
};

std::pair<SEXP, std::vector<Collector_Ptr>> parse_fields_spec(cpp11::list spec_list,
                                                              bool vector_allows_empty_list) {
  cpp11::writable::strings keys;
  std::vector<Collector_Ptr> col_vec;

  for (const cpp11::list& elt : spec_list) {
    cpp11::r_string key =  cpp11::strings(elt["key"])[0];
    keys.push_back(key);
    cpp11::r_string type = cpp11::strings(elt["type"])[0];

    if (type == "sub") {
      cpp11::list sub_spec = elt["spec"];
      auto spec_pair = parse_fields_spec(sub_spec, vector_allows_empty_list);
      col_vec.push_back(Collector_Ptr(new Collector_Same_Key(spec_pair.first, spec_pair.second)));
      continue;
    }

    cpp11::r_string name = cpp11::strings(elt["name"])[0];
    int location = cpp11::integers(elt["location"])[0];
    cpp11::r_bool required = cpp11::logicals(elt["required"])[0];

    if (type == "row") {
      cpp11::list fields = elt["fields"];
      auto spec_pair = parse_fields_spec(fields, vector_allows_empty_list);
      col_vec.push_back(Collector_Ptr(new Collector_Tibble(spec_pair.first, spec_pair.second, required, location, name)));
      continue;
    } else if (type == "df") {
      cpp11::list fields = elt["fields"];
      auto spec_pair = parse_fields_spec(fields, vector_allows_empty_list);

      cpp11::sexp names_col = elt["names_col"];
      if (!Rf_isNull(names_col)) {
        names_col = cpp11::strings(names_col)[0];
      }

      col_vec.push_back(
        Collector_Ptr(
          new Collector_List_Of_Tibble(spec_pair.first, spec_pair.second, names_col, required, location, name)
        )
      );
      continue;
    }

    Field_Args field_args = Field_Args(elt["fill"], elt["transform"]);

    if (type == "variant" || type == "unspecified") {
      col_vec.push_back(Collector_Ptr(new Collector_List(required, location, name, field_args)));
      continue;
    }

    field_args.ptype = elt["ptype"];
    cpp11::sexp ptype_inner = elt["ptype_inner"];
    field_args.ptype_inner = ptype_inner;
    if (type == "scalar") {
      if (vec_is(ptype_inner, tibblify_shared_empty_lgl)) {
        col_vec.push_back(Collector_Ptr(new Collector_Scalar2<int, cpp11::r_bool>(required, location, name, field_args)));
      } else if (vec_is(ptype_inner, tibblify_shared_empty_int)) {
        col_vec.push_back(Collector_Ptr(new Collector_Scalar2<int, int>(required, location, name, field_args)));
      } else if (vec_is(ptype_inner, tibblify_shared_empty_dbl)) {
        col_vec.push_back(Collector_Ptr(new Collector_Scalar2<double, double>(required, location, name, field_args)));
      } else if (vec_is(ptype_inner, tibblify_shared_empty_chr)) {
        col_vec.push_back(Collector_Ptr(new Collector_Scalar2<SEXP, cpp11::r_string>(required, location, name, field_args)));
      } else {
        cpp11::sexp na = elt["na"];
        col_vec.push_back(Collector_Ptr(new Collector_Scalar(required, location, name, field_args, na)));
      }
    } else if (type == "vector") {
      cpp11::r_string input_form = cpp11::strings(elt["input_form"])[0];
      Vector_Args vector_args {
        string_to_form_enum(input_form),
        vector_allows_empty_list,
        .names_to = elt["names_to"],
        .values_to = elt["values_to"],
        .na = elt["na"]
      };

      col_vec.push_back(Collector_Ptr(new Collector_Vector(required, location, name, field_args, vector_args))
      );
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

  bool vector_allows_empty_list = cpp11::r_bool(cpp11::logicals(spec_list["vector_allows_empty_list"])[0]);
  auto spec_pair = parse_fields_spec(spec_list["fields"], vector_allows_empty_list);
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
