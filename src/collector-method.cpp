/* TODOs
 * [ ] heuristic to detect object vs list of object -> appropriate error message
 * [ ] add other scalar types: complex, raw
 */

#include <cpp11.hpp>
#include <plogr.h>

#include <vector>
#include "tibblify.h"
#include "utils.h"
#include "Path.h"
#include "conditions.h"

inline r_obj* apply_transform(r_obj* value, r_obj* fn) {
  LOG_DEBUG;

  // from https://github.com/r-lib/vctrs/blob/9b65e090da2a0f749c433c698a15d4e259422542/src/names.c#L83
  r_obj* call = KEEP(r_call2(syms_transform, syms_value));

  r_obj* mask = KEEP(r_new_environment(R_GlobalEnv));
  Rf_defineVar(syms_transform, fn, mask);
  Rf_defineVar(syms_value, value, mask);
  r_obj* out = KEEP(r_eval(call, mask));

  FREE(3);
  return out;
}

inline r_obj* vec_flatten(r_obj* value, r_obj* ptype) {
  LOG_DEBUG;

  r_obj* call = KEEP(r_call3(syms_vec_flatten,
                               value,
                               ptype));
  r_obj* out = r_eval(call, tibblify_ns_env);
  FREE(1);
  return(out);
}

inline bool is_list_of(r_obj* value, r_obj* ptype) {
  if (!Rf_inherits(value, "vctrs_list_of")) {
    LOG_DEBUG << "not a list_of";
    return false;
  }

  r_obj* value_ptype = Rf_getAttrib(value, r_sym("ptype"));

  if (vec_is(value_ptype, ptype)) {
    LOG_DEBUG << "correct ptype";
    return true;
  } else {
    LOG_DEBUG << "not correct ptype";
    return false;
  }
  // return vec_is(value_ptype, ptype);
}

inline r_obj* vec_init_along(r_obj* ptype, r_obj* along) {
  r_obj* n_rows_sexp = KEEP(r_int(short_vec_size(along)));
  r_obj* call = KEEP(r_call3(r_sym("vec_init"),
                               ptype,
                               n_rows_sexp));
  r_obj* out = r_eval(call, tibblify_ns_env);
  FREE(2);
  return(out);
}

class Collector {
public:
  virtual ~ Collector() {};

  // reserve space
  virtual void init(r_ssize& length) = 0;
  // number of columns it expands in the end
  // only really relevant for `Collector_Same_Key`
  virtual int size() const = 0;

  virtual bool colmajor_nrows(r_obj* value, r_ssize& n_rows) = 0;
  // if key is found -> add `object` to internal memory
  virtual void add_value(r_obj* object, Path& path) = 0;

  virtual inline void add_value_colmajor(r_obj* value, r_ssize& n_rows, Path& path) = 0;
  // if key is absent -> check if field is required; if not add `default`
  virtual void add_default(bool check, Path& path) = 0;

  virtual void add_default_colmajor(bool check, Path& path) = 0;
  // assign data to input `list` at correct location and update `names`
  virtual void assign_data(r_obj* list, r_obj* names) const = 0;
};

using Collector_Ptr = std::unique_ptr<Collector>;


class Collector_Base : public Collector {
protected:
  const bool required;
  const int col_location;
  r_obj* name;
  r_obj* transform;
  r_obj* default_value;
  r_obj* ptype;
  r_obj* ptype_inner;

  int current_row = 0;
  cpp11::writable::list data;

public:
  Collector_Base(bool& required_, int& col_location_, r_obj* name_, const Field_Args& field_args)
    : required(required_)
  , col_location(col_location_)
  , name(name_)
  , transform(field_args.transform)
  , default_value(field_args.default_sexp)
  , ptype(field_args.ptype)
  , ptype_inner(field_args.ptype_inner)
  { }

  inline void init(r_ssize& length) {
    LOG_DEBUG;

    this->data = r_alloc_list(length);
    this->current_row = 0;
  }

  inline int size() const {
    return 1;
  }

  inline bool colmajor_nrows(r_obj* value, r_ssize& n_rows) {
    LOG_DEBUG;

    if (value == r_null) {
      return(false);
    }

    n_rows = r_length(value);
    return(true);
  }

  inline void add_value_colmajor(r_obj* value, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    if (r_typeof(value) != R_TYPE_list) {
      stop_colmajor_non_list_element(path, value);
    }

    check_colmajor_size(value, n_rows, path);
    r_obj* const * v_value = r_list_cbegin(value);

    for (r_ssize row = 0; row < n_rows; row++) {
      this->add_value(*v_value, path);
      ++v_value;
    }
  }

  inline void add_default(bool check, Path& path) {
    LOG_DEBUG;

    if (check && required) stop_required(path);
    r_list_poke(this->data, this->current_row++, this->default_value);
  }

  void add_default_colmajor(bool check, Path& path) {
    LOG_DEBUG;

    if (check && required) stop_required(path);

    const r_ssize n_rows = r_length(this->data);
    for (r_ssize row = 0; row < n_rows; row++) {
      r_list_poke(this->data, this->current_row++, this->default_value);
    }
  }

  inline void assign_data(r_obj* list, r_obj* names) const {
    LOG_DEBUG;

    r_obj* data = this->data;
    if (this->transform != r_null) data = apply_transform(data, this->transform);
    KEEP(data);

    r_list_poke(list, this->col_location, data);
    r_chr_poke(names, this->col_location, this->name);
    FREE(1);
  }
};

class Collector_Scalar : public Collector_Base {
private:
  r_obj* na;
  cpp11::sexp data_colmajor;
  bool colmajor = false;

public:
  Collector_Scalar(bool required_, int col_location_, r_obj* name_, Field_Args& field_args, r_obj* na_)
    : Collector_Base(required_, col_location_, name_, field_args)
  , na(na_)
  { }

  inline bool colmajor_nrows(r_obj* value, r_ssize& n_rows) {
    LOG_DEBUG;

    if (value == r_null) {
      return(false);
    }

    n_rows = short_vec_size(value);
    return(true);
  }

  inline void add_value(r_obj* value, Path& path) {
    LOG_DEBUG;

    if (value == r_null) {
      LOG_DEBUG << "NULL";
      r_list_poke(this->data, this->current_row++, this->na);
      return;
    }

    r_obj* value_casted = KEEP(vec_cast(value, this->ptype_inner));
    r_ssize size = short_vec_size(value_casted);
    if (size != 1) {
      stop_scalar(path, size);
    }

    r_list_poke(this->data, this->current_row++, value_casted);
    FREE(1);
  }

  inline void add_value_colmajor(r_obj* value, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;
    this->colmajor = true;

    if (value == r_null) {
      this->add_default_colmajor(false, path);
      return;
    }

    this->data_colmajor = vec_cast(value, ptype_inner);
  }

  inline void add_default_colmajor(bool check, Path& path) {
    LOG_DEBUG;
    this->colmajor = true;

    if (check && this->required) stop_required(path);
    this->data_colmajor = vec_init_along(this->ptype, this->data);
  }

  inline void assign_data(r_obj* list, r_obj* names) const {
    LOG_DEBUG;

    r_obj* value = R_NilValue;
    if (this->colmajor) {
      value = this->data_colmajor;
    } else {
      value = vec_flatten(this->data, this->ptype_inner);
    }
    KEEP(value);

    if (this->transform != r_null) value = apply_transform(value, this->transform);
    r_obj* value_cast = KEEP(vec_cast(KEEP(value), this->ptype));

    r_list_poke(list, this->col_location, value_cast);
    r_chr_poke(names, this->col_location, this->name);
    FREE(3);
  }
};

template <typename CPP11_TYPE>
r_obj* r_alloc_vector(r_ssize& length);

template <>
r_obj* r_alloc_vector<cpp11::r_bool>(r_ssize& length) {
  return(r_alloc_logical(length));
}

template <>
r_obj* r_alloc_vector<int>(r_ssize& length) {
  return(r_alloc_integer(length));
}

template <>
r_obj* r_alloc_vector<double>(r_ssize& length) {
  return(r_alloc_double(length));
}

template <>
r_obj* r_alloc_vector<cpp11::r_string>(r_ssize& length) {
  return(r_alloc_character(length));
}

template <typename T, typename CPP11_TYPE>
T* r_vector_ptr(r_obj* data);

template <>
int* r_vector_ptr<int, cpp11::r_bool>(r_obj* data) {
  return(LOGICAL(data));
}

template <>
int* r_vector_ptr<int, int>(r_obj* data) {
  return(INTEGER(data));
}

template <>
double* r_vector_ptr<double, double>(r_obj* data) {
  return(REAL(data));
}

template <>
r_obj** r_vector_ptr<r_obj*, cpp11::r_string>(r_obj* data) {
  return(STRING_PTR(data));
}

template <typename T, typename CPP11_TYPE>
T r_vector_cast(r_obj* data);

template <>
int r_vector_cast<int, cpp11::r_bool>(r_obj* data) {
  return(Rf_asLogical(data));
}

template <>
int r_vector_cast<int, int>(r_obj* data) {
  return(Rf_asInteger(data));
};

template <>
double r_vector_cast<double, double>(r_obj* data) {
  return(Rf_asReal(data));
}

template <>
r_obj* r_vector_cast<r_obj*, cpp11::r_string>(r_obj* data) {
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
  Collector_Scalar2(bool required_, int col_location_, r_obj* name_, Field_Args& field_args)
    : Collector_Base(required_, col_location_, name_, field_args)
  , default_value(convert_default(field_args.default_sexp))
  { }

  inline void init(r_ssize& length) {
    LOG_DEBUG;

    this->data = r_alloc_vector<CPP11_TYPE>(length);
    this->data_ptr = r_vector_ptr<T, CPP11_TYPE>(this->data);
  }

  inline void add_value(r_obj* value, Path& path) {
    LOG_DEBUG;

    if (value == r_null) {
      LOG_DEBUG << "NULL";

      *this->data_ptr = this->na;
      ++this->data_ptr;
      return;
    }

    r_obj* value_casted = KEEP(vec_cast(value, this->ptype_inner));
    r_ssize size = short_vec_size(value_casted);
    if (size != 1) {
      stop_scalar(path, size);
    }

    *this->data_ptr = r_vector_cast<T, CPP11_TYPE>(value_casted);
    ++this->data_ptr;
    FREE(1);
  }

  inline void add_value_colmajor(r_obj* value, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    if (value == r_null) {
      add_default_colmajor(false, path);
      return;
    }

    check_colmajor_size(value, n_rows, path);
    this->data = vec_cast(value, this->ptype_inner);
  }

  inline void add_default(bool check, Path& path) {
    LOG_DEBUG;

    if (check && this->required) stop_required(path);
    *this->data_ptr = this->default_value;
    ++this->data_ptr;
  }

  inline void add_default_colmajor(bool check, Path& path) {
    LOG_DEBUG;

    if (check && this->required) stop_required(path);
    this->data = vec_init_along(this->ptype_inner, this->data);
  }

  inline void assign_data(r_obj* list, r_obj* names) const {
    LOG_DEBUG;

    r_obj* data = this->data;
    if (this->transform != r_null) data = apply_transform(data, this->transform);

    r_obj* data_cast = KEEP(vec_cast(KEEP(data), this->ptype));
    r_list_poke(list, this->col_location, data_cast);
    FREE(2);
    r_chr_poke(names, this->col_location, this->name);
  }
};

class Collector_Vector : public Collector_Base {
private:
  const vector_input_form input_form;
  const bool uses_names_col;
  const bool uses_values_col;
  r_obj* output_col_names;
  const bool vector_allows_empty_list;
  r_obj* na;
  const cpp11::sexp empty_element;
  const cpp11::sexp elt_transform;

  r_obj* get_list_of_ptype() const {
    LOG_DEBUG;

    if (this->uses_values_col) {
      auto ptype_df = init_out_df(0);
      if (this->uses_names_col) {
        ptype_df[0] = tibblify_shared_empty_chr;
        ptype_df[1] = this->ptype;
      } else {
        ptype_df[0] = this->ptype;
      }
      return ptype_df;
    } else {
      return this->ptype;
    }
  }

  r_obj* get_output_col_names(r_obj* names_to_, r_obj* values_to_) {
    LOG_DEBUG;

    if (values_to_ == r_null) {
      return(NULL);
    }

    if (names_to_ == r_null) {
      return(values_to_);
    } else {
      cpp11::writable::strings col_names(2);
      col_names[0] = cpp11::strings(names_to_)[0];
      col_names[1] = cpp11::strings(values_to_)[0];
      return(col_names);
    }
  }

  cpp11::writable::list init_out_df(r_ssize n_rows) const {
    return(init_df(n_rows, this->output_col_names));
  }

  r_obj* unchop_value(r_obj* value, Path& path) {
    LOG_DEBUG;

    // FIXME if `vec_assign()` gets exported this should use
    // `vec_init()` + `vec_assign()`
    r_ssize loc_first_null = -1;
    r_ssize n = r_length(value);
    r_obj* const * v_value = r_list_cbegin(value);

    for (r_ssize i = 0; i < n; i++, v_value++) {
      if (*v_value == r_null) {
        loc_first_null = i;
        break;
      }

      if (vec_size(*v_value) != 1) {
        stop_vector_wrong_size_element(path, this->input_form, value);
      }
    }

    if (loc_first_null == -1) {
      return(vec_flatten(value, this->ptype_inner));
    }

    // Theoretically a shallow duplicate should be more efficient but in
    // benchmarks this didn't seem to be the case...
    r_obj* out_list = KEEP(Rf_shallow_duplicate(value));
    for (r_ssize i = loc_first_null; i < n; i++, v_value++) {
      if (*v_value == r_null) {
        r_list_poke(out_list, i, this->na);
        continue;
      }

      if (vec_size(*v_value) != 1) {
        stop_vector_wrong_size_element(path, this->input_form, value);
      }
    }

    r_obj* out = vec_flatten(out_list, this->ptype_inner);
    FREE(1);
    return out;
  }

public:
  Collector_Vector(bool required_, int col_location_, r_obj* name_, Field_Args& field_args, Vector_Args vector_args)
    : Collector_Base(required_, col_location_, name_, field_args)
  , input_form(vector_args.input_form)
  , uses_names_col(vector_args.names_to != r_null)
  , uses_values_col(vector_args.values_to != r_null)
  , output_col_names(get_output_col_names(vector_args.names_to, vector_args.values_to))
  , vector_allows_empty_list(vector_args.vector_allows_empty_list)
  , na(vector_args.na)
  , empty_element(vec_init_along(field_args.ptype, R_NilValue))
  , elt_transform(vector_args.elt_transform)
  { }

  inline void init(r_ssize& length) {
    LOG_DEBUG;

    Collector_Base::init(length);

    cpp11::sexp list_of_ptype = get_list_of_ptype();
    set_list_of_attributes(this->data, list_of_ptype);
  }

  inline void add_value(r_obj* value, Path& path) {
    LOG_DEBUG;

    if (value == r_null) {
      LOG_DEBUG << "NULL";

      r_list_poke(this->data, this->current_row++, R_NilValue);
      return;
    }

    if (this->input_form == vector_input_form::vector && this->vector_allows_empty_list) {
      if (r_length(value) == 0 && r_typeof(value) == R_TYPE_list) {
        r_list_poke(this->data, this->current_row++, this->empty_element);
        return;
      }
    }

    r_obj* names = Rf_getAttrib(value, R_NamesSymbol);
    if (this->input_form == vector_input_form::scalar_list || this->input_form == vector_input_form::object) {
      // FIXME should check with `vec_is_list()`?
      if (r_typeof(value) != R_TYPE_list) {
        stop_vector_non_list_element(path, this->input_form, value);
      }

      if (this->input_form == vector_input_form::object && names == r_null) {
        stop_object_vector_names_is_null(path);
      }

      value = unchop_value(value, path);
    }

    if (this->elt_transform != r_null) value = apply_transform(value, this->elt_transform);
    r_obj* value_casted = KEEP(vec_cast(KEEP(value), this->ptype));

    if (this->uses_values_col) {
      r_ssize size = short_vec_size(value_casted);
      cpp11::writable::list df = init_out_df(size);

      if (this->uses_names_col) {
        if (names == r_null) {
          df[0] = na_chr(vec_size(value));
        } else {
          df[0] = names;
        }
        df[1] = value_casted;
      } else {
        df[0] = value_casted;
      }

      r_list_poke(this->data, this->current_row++, df);
    } else {
      r_list_poke(this->data, this->current_row++, value_casted);
    }
    FREE(2);
  }

  inline void assign_data(r_obj* list, r_obj* names) const {
    LOG_DEBUG;

    r_obj* data = this->data;
    if (this->transform != r_null) data = apply_transform(data, this->transform);
    KEEP(data);

    cpp11::writable::list out_ptype;
    if (this->uses_values_col) {
      auto ptype_df = init_out_df(0);
      if (this->uses_names_col) {
        ptype_df[0] = tibblify_shared_empty_chr;
        ptype_df[1] = this->ptype;
      } else {
        ptype_df[0] = this->ptype;
      }
      set_list_of_attributes(out_ptype, ptype_df);
    } else {
      set_list_of_attributes(out_ptype, this->ptype);
    }

    if (!is_list_of(data, out_ptype)) {
      LOG_DEBUG << "cast";
      data = vec_cast(data, out_ptype);
    }
    KEEP(data);
    r_list_poke(list, this->col_location, data);
    r_chr_poke(names, this->col_location, this->name);
    FREE(2);
  }
};


class Collector_List : public Collector_Base {
private:
  cpp11::sexp elt_transform;
public:
  Collector_List(bool required_, int col_location_, r_obj* name_, Field_Args& field_args, cpp11::sexp elt_transform_ = R_NilValue)
    : Collector_Base(required_, col_location_, name_, field_args)
  , elt_transform(elt_transform_)
  { }

  inline void add_value(r_obj* value, Path& path) {
    LOG_DEBUG;

    if (value == r_null) {
      LOG_DEBUG << "NULL";

      r_list_poke(this->data, this->current_row++, R_NilValue);
      return;
    }

    if (this->elt_transform != r_null) value = apply_transform(value, this->elt_transform);
    r_list_poke(this->data, this->current_row++, value);
  }

  inline void add_value_colmajor(r_obj* value, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    check_colmajor_size(value, n_rows, path);
    if (this->elt_transform != r_null) {
      cpp11::stop("`elt_transform` not supported for `input_form = \"colmajor\"");
    }

    if (this->transform == r_null) {
      this->data = value;
    } else {
      Collector_Base::add_value_colmajor(value, n_rows, path);
    }
  }
};

inline r_obj* collector_vec_to_df(const std::vector<Collector_Ptr>& collector_vec,
                                r_ssize n_rows,
                                int n_extra_cols) {
  LOG_DEBUG;

  int n_cols = n_extra_cols;
  for (const Collector_Ptr& collector : collector_vec) {
    n_cols += (*collector).size();
  }

  r_obj* df = KEEP(r_alloc_list(n_cols));
  r_obj* names = KEEP(r_alloc_character(n_cols));

  for (const Collector_Ptr& collector : collector_vec) {
    (*collector).assign_data(df, names);
  }
  set_df_attributes(df, names, n_rows);

  FREE(2);
  return df;
}

inline void check_names(r_obj* field_names,
                        const int ind[],
                        const int n_fields,
                        const Path& path) {
  LOG_DEBUG;

  if (n_fields == 0) return;

  r_obj* const * v_field_names = r_chr_cbegin(field_names);
  r_obj* field_nm = v_field_names[ind[0]];
  if (field_nm == NA_STRING || field_nm == strings_empty) stop_empty_name(path, ind[0]);

  for (int field_index = 1; field_index < n_fields; field_index++) {
    r_obj* field_nm_prev = field_nm;
    field_nm = v_field_names[ind[field_index]];
    if (field_nm == field_nm_prev) stop_duplicate_name(path, field_nm);

    if (field_nm == NA_STRING || field_nm == strings_empty) stop_empty_name(path, ind[field_index]);
  }
}

r_ssize get_collector_vec_rows(r_obj* object_list,
                                const std::vector<Collector_Ptr>& collector_vec,
                                r_obj* keys,
                                const int& n_keys) {
  LOG_DEBUG;

  // CAREFUL this relies on the keys being sorted

  // TODO check if list

  r_obj* field_names = Rf_getAttrib(object_list, R_NamesSymbol);
  const r_ssize n_fields = short_vec_size(object_list);

  if (n_fields == 0) {
    r_ssize n_rows (0);
    return(n_rows);
  }

  r_ssize n_rows;
  auto key_match_ind = match_chr(keys, field_names);
  r_obj* const * v_object_list = r_list_cbegin(object_list);

  for (int key_index = 0; key_index < n_keys; key_index++) {
    int loc = key_match_ind[key_index];
    LOG_DEBUG << "match loc: " << loc << " - " << r_chr_get_c_string(keys, key_index);

    if (loc < 0) {
      continue;
    }

    r_obj* field = v_object_list[loc];
    if ((*collector_vec[key_index]).colmajor_nrows(field, n_rows)) {
      LOG_DEBUG << "found rows: " << n_rows;
      return(n_rows);
    }
  }

  // TODO better error
  cpp11::stop("Could not determine number of rows.");
}

void parse_colmajor_impl(r_obj* object_list,
                         r_obj* keys,
                         const int& n_keys,
                         r_ssize& n_rows,
                         std::vector<Collector_Ptr>& collector_vec,
                         Path& path) {
  LOG_DEBUG;

  //  TODO what if 0 fields?

  r_obj* field_names = Rf_getAttrib(object_list, R_NamesSymbol);
  // TODO `check_names()`
  if (field_names == R_NilValue) stop_names_is_null(path);

  auto key_match_ind = match_chr(keys, field_names);
  r_obj* const * v_object_list = r_list_cbegin(object_list);
  r_obj* const * v_keys = r_chr_cbegin(keys);

  path.down();
  for (int key_index = 0; key_index < n_keys; key_index++, v_keys++) {
    path.replace(*v_keys);
    int loc = key_match_ind[key_index];
    LOG_DEBUG << "key: " << CHAR(*v_keys);

    if (loc < 0) {
      (*collector_vec[key_index]).add_default_colmajor(true, path);
    } else {
      r_obj* field = v_object_list[loc];
      (*collector_vec[key_index]).add_value_colmajor(field, n_rows, path);
    }
  }
  path.up();
}

class Multi_Collector {
private:
  cpp11::strings field_names_prev;
  int n_fields_prev = 0;
  static const int INDEX_SIZE = 256;
  int ind[INDEX_SIZE];
  std::vector<int> key_match_ind;

  inline void update_fields(r_obj* field_names, const int& n_fields, Path& path) {
    const bool fields_have_changed = this->have_fields_changed(field_names, n_fields);
    // only update `ind` if necessary as `R_orderVector1()` is pretty slow
    if (!fields_have_changed) {
      return;
    }

    LOG_DEBUG << "field have changed";
    this->update_order(field_names, n_fields);

    // TODO use `order_chr()`?
    R_orderVector1(this->ind, n_fields, field_names, FALSE, FALSE);
    check_names(field_names, this->ind, n_fields, path);
  }

  inline bool have_fields_changed(r_obj* field_names, const int& n_fields) const {
    LOG_DEBUG << "n_fields: " << n_fields;

    if (n_fields != this->n_fields_prev) return true;

    if (n_fields >= INDEX_SIZE) cpp11::stop("At most 256 fields are supported");
    r_obj* const * v_field_names = r_chr_cbegin(field_names);
    r_obj* const * v_field_names_prev = r_chr_cbegin(this->field_names_prev);
    const int n = std::max(n_fields, this->n_fields_prev);
    for (int i = 0; i < n; i++, v_field_names++, v_field_names_prev++) {
      LOG_DEBUG << i << " - " << CHAR(*v_field_names) << " - " << CHAR(*v_field_names_prev);
      if (*v_field_names != *v_field_names_prev) {
        return true;
      }
    }

    return false;
  }

  inline void update_order(r_obj* field_names, const int& n_fields) {
    LOG_DEBUG;

    this->n_fields_prev = n_fields;
    this->field_names_prev = field_names;
    this->key_match_ind = match_chr(this->keys, field_names);
  }

protected:
  cpp11::writable::strings keys;
  std::vector<Collector_Ptr> collector_vec;
  const int n_keys;

  inline r_obj* get_data(r_obj* object_list, r_ssize n_rows) {
    LOG_DEBUG;

    r_obj* out = collector_vec_to_df(std::move(this->collector_vec), n_rows, 0);
    return(out);
  }

public:
  Multi_Collector(r_obj* keys_, std::vector<Collector_Ptr>& collector_vec_)
    : n_keys(r_length(keys_))
  {
    LOG_DEBUG;

    int n_keys = r_length(keys_);
    // TODO should use `order_chr()`?
    R_orderVector1(this->ind, n_keys, keys_, FALSE, FALSE);

    this->keys = r_alloc_character(n_keys);
    for(int i = 0; i < n_keys; i++) {
      int key_index = this->ind[i];
      r_chr_poke(this->keys, i, r_chr_get(keys_, key_index));
      this->collector_vec.emplace_back(std::move(collector_vec_[key_index]));
    }

    this->update_order(keys_, n_keys);
  }

  inline void init(r_ssize& length) {
    LOG_DEBUG;

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).init(length);
    }
  }

  inline bool colmajor_nrows(r_obj* value, r_ssize& n_rows) {
    LOG_DEBUG;

    if (value == r_null) {
      return(false);
    }

    for (const Collector_Ptr& collector : this->collector_vec) {
      if ((*collector).colmajor_nrows(value, n_rows)) {
        return(true);
      }
    }

    return(false);
  }

  inline void add_value(r_obj* object, Path& path) {
    LOG_DEBUG;

    if (object == r_null) {
      LOG_DEBUG << "NULL";

      this->add_default(false, path);
      return;
    }

    const int n_fields = r_length(object);
    if (n_fields == 0) {
      this->add_default(true, path);
      return;
    }

    r_obj* field_names = Rf_getAttrib(object, R_NamesSymbol);
    if (field_names == R_NilValue) stop_names_is_null(path);

    this->update_fields(field_names, n_fields, path);

    // TODO r_list_cbegin only works if object is a list
    r_obj* const * v_keys = r_chr_cbegin(this->keys);
    r_obj* const * v_object = r_list_cbegin(object);

    path.down();
    for (int key_index = 0; key_index < this->n_keys; key_index++) {
      int loc = this->key_match_ind[key_index];
      r_obj* cur_key = v_keys[key_index];
      LOG_DEBUG << "match loc: " << loc << " - " << CHAR(cur_key);
      path.replace(cur_key);

      if (loc < 0) {
        (*this->collector_vec[key_index]).add_default(true, path);
      } else {
        LOG_DEBUG << " - " << r_chr_get_c_string(field_names, loc);
        auto cur_value = v_object[loc];
        (*this->collector_vec[key_index]).add_value(cur_value, path);
      }
    }
    path.up();
  }

  inline void add_value_colmajor(r_obj* object_list, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    parse_colmajor_impl(object_list,
                        this->keys,
                        this->n_keys,
                        n_rows,
                        this->collector_vec,
                        path);
  }

  inline void add_default(bool check, Path& path) {
    LOG_DEBUG;

    path.down();
    r_obj* const * v_keys = r_chr_cbegin(this->keys);
    for (int key_index = 0; key_index < this->n_keys; key_index++, v_keys++) {
      path.replace(*v_keys);
      (*this->collector_vec[key_index]).add_default(check, path);
    }
    path.up();
  }
};

class Collector_Same_Key : public Collector, Multi_Collector {
protected:
  int n_keys;

public:
  Collector_Same_Key(r_obj* keys_, std::vector<Collector_Ptr>& collector_vec_)
    : Multi_Collector(keys_, collector_vec_)
  , n_keys(r_length(keys_))
  { }

  inline int size() const {
    LOG_DEBUG;

    int size = 0;
    for (const Collector_Ptr& collector : this->collector_vec) {
      size += (*collector).size();
    }

    return size;
  }

  inline void init(r_ssize& length) {
    LOG_DEBUG;

    Multi_Collector::init(length);
  }

  inline bool colmajor_nrows(r_obj* value, r_ssize& n_rows) {
    LOG_DEBUG;

    return(Multi_Collector::colmajor_nrows(value, n_rows));
  }

  inline void add_value(r_obj* object, Path& path) {
    LOG_DEBUG;

    Multi_Collector::add_value(object, path);
  }

  inline void add_value_colmajor(r_obj* object, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    Multi_Collector::add_value_colmajor(object, n_rows, path);
  }

  inline void add_default(bool check, Path& path) {
    LOG_DEBUG;

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).add_default(check, path);
    }
  }

  inline void add_default_colmajor(bool check, Path& path) {
    LOG_DEBUG;

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).add_default_colmajor(check, path);
    }
  }

  inline void assign_data(r_obj* list, r_obj* names) const {
    LOG_DEBUG;

    for (const Collector_Ptr& collector : this->collector_vec) {
      (*collector).assign_data(list, names);
    }
  }
};

class Collector_Tibble : public Collector_Base, Multi_Collector {
private:
  r_ssize n_rows;

public:
  Collector_Tibble(r_obj* keys_, std::vector<Collector_Ptr>& col_vec_,
                   bool required_, int col_location_, r_obj* name_)
    : Collector_Base(required_, col_location_, name_, Field_Args())
  , Multi_Collector(keys_, col_vec_)
  { }

  inline void init(r_ssize& length) {
    LOG_DEBUG;

    this->n_rows = length;
    Multi_Collector::init(length);
  }

  inline bool colmajor_nrows(r_obj* value, r_ssize& n_rows) {
    LOG_DEBUG;

    if (value == r_null) {
      return(false);
    }

    if (r_typeof(value) != R_TYPE_list) {
      // TODO should pass along path?
      Path path;
      stop_colmajor_non_list_element(path, value);
    }

    n_rows = get_collector_vec_rows(value,
                                    this->collector_vec,
                                    this->keys,
                                    this->n_keys);

    return(true);
  }

  inline void add_value(r_obj* object, Path& path) {
    LOG_DEBUG;

    Multi_Collector::add_value(object, path);
  }

  inline void add_value_colmajor(r_obj* object, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    Multi_Collector::add_value_colmajor(object, n_rows, path);
  }

  inline void add_default(bool check, Path& path) {
    LOG_DEBUG;

    if (check && required) stop_required(path);
    path.down();
    for (int i = 0; i < this->n_keys; i++) {
      path.replace((cpp11::r_string) this->keys[i]);
      (*this->collector_vec[i]).add_default(false, path);
    }
    path.up();
  }

  inline void assign_data(r_obj* list, r_obj* names) const {
    LOG_DEBUG;

    r_obj* data = KEEP(collector_vec_to_df(std::move(this->collector_vec), this->n_rows, 0));

    r_list_poke(list, this->col_location, data);
    r_chr_poke(names, this->col_location, this->name);
    FREE(1);
  }
};

class Parser_Object_List : Multi_Collector {
private:
  const std::string input_form;
  const SEXP names_col;
  const bool has_names_col;

  inline r_obj* get_data(r_obj* object_list, r_ssize n_rows) {
    LOG_DEBUG;

    int n_extra_cols = this->has_names_col ? 1 : 0;

    r_obj* out = KEEP(collector_vec_to_df(std::move(this->collector_vec), n_rows, n_extra_cols));
    r_obj* names = Rf_getAttrib(out, R_NamesSymbol);

    if (this->has_names_col) {
      r_list_poke(out, 0, my_vec_names2(object_list));
      r_chr_poke(names, 0, this->names_col);
    }

    FREE(1);
    return(out);
  }

  void parse_colmajor(r_obj* object_list, r_ssize& n_rows, Path& path) {
    LOG_DEBUG;

    parse_colmajor_impl(object_list,
                       this->keys,
                       this->n_keys,
                       n_rows,
                       this->collector_vec,
                       path);
  }

public:
  Parser_Object_List(r_obj* keys_,
                     std::vector<Collector_Ptr>& col_vec_,
                     std::string input_form_,
                     r_obj* names_col_ = R_NilValue)
    : Multi_Collector(keys_, col_vec_)
  , input_form(input_form_)
  , names_col(names_col_)
  , has_names_col(names_col_ != r_null)
  { }

  inline r_obj* get_ptype() {
    r_ssize n_rows = 0;
    this->init(n_rows);

    int n_extra_cols = this->has_names_col ? 1 : 0;

    r_obj* out = KEEP(collector_vec_to_df(std::move(this->collector_vec), n_rows, n_extra_cols));
    r_obj* names = Rf_getAttrib(out, R_NamesSymbol);

    if (this->has_names_col) {
      r_list_poke(out, 0, tibblify_shared_empty_chr);
      r_chr_poke(names, 0, this->names_col);
    }

    FREE(1);

    return(out);
  }

  inline r_obj* parse(r_obj* object_list, Path& path) {
    LOG_DEBUG;

    if (this->input_form == "colmajor") {
      // FIXME path handling is quite confusing here...
      path.up();
      r_obj* field_names = Rf_getAttrib(object_list, R_NamesSymbol);
      const r_ssize n_fields = r_length(field_names);
      if (field_names == R_NilValue) stop_names_is_null(path);

      auto ind = order_chr(field_names);
      check_names(field_names, ind.data(), n_fields, path);

      r_ssize n_rows = get_collector_vec_rows(object_list, this->collector_vec, this->keys, this->n_keys);
      this->init(n_rows);

      this->parse_colmajor(object_list, n_rows, path);
      auto out = this->get_data(object_list, n_rows);
      path.down();
      return(out);
    } else if (input_form == "rowmajor") {
      r_ssize n_rows = short_vec_size(object_list);
      LOG_DEBUG << "===== Start init ======";
      this->init(n_rows);

      if (Rf_inherits(object_list, "data.frame")) {
        LOG_DEBUG << "===== Start parsing colmajor ======";
        this->parse_colmajor(object_list, n_rows, path);
        return this->get_data(object_list, n_rows);
      } else if (vec_is_list(object_list)) {
        LOG_DEBUG << "===== Start parsing rowmajor - list ======";
        r_obj* const * v_object_list = r_list_cbegin(object_list);
        for (r_ssize row_index = 0; row_index < n_rows; row_index++) {
          path.replace(row_index);
          this->add_value(v_object_list[row_index], path);
        }
      } else {
        r_obj* slice_index_int = KEEP(r_alloc_integer(1));
        int* slice_index_int_ptr = INTEGER(slice_index_int);

        for (r_ssize row_index = 0; row_index < n_rows; row_index++) {
          path.replace(row_index);
          *slice_index_int_ptr = row_index + 1;
          this->add_value(KEEP(vec_slice_impl(object_list, slice_index_int)), path);
          FREE(1);
        }
        FREE(1);
      }
      return this->get_data(object_list, n_rows);
    }

    cpp11::stop("Unexpected input form"); // # nocov
  }
};

class Parser_Object : Multi_Collector {
public:
  Parser_Object(r_obj* keys_, std::vector<Collector_Ptr>& col_vec_)
    : Multi_Collector(keys_, col_vec_)
  { }

  inline r_obj* parse(r_obj* object, Path& path) {
    LOG_DEBUG;

    r_ssize n_rows = 1;
    LOG_DEBUG << "====== Object -> init ======";
    this->init(n_rows);

    LOG_DEBUG << "====== Object -> parse ======";
    this->add_value(object, path);

    r_obj* out = collector_vec_to_df(std::move(this->collector_vec), n_rows, 0);
    return(out);
  }
};


class Collector_List_Of_Tibble : public Collector_Base {
private:
  const std::unique_ptr<Parser_Object_List> parser_ptr;
  const std::string input_form;

public:
  Collector_List_Of_Tibble(r_obj* keys_, std::vector<Collector_Ptr>& col_vec_, r_obj* names_col_,
                           bool required_, int& col_location_, r_obj* name_, std::string input_form_)
    : Collector_Base(required_, col_location_, name_,  Field_Args())
  , parser_ptr(std::unique_ptr<Parser_Object_List>(new Parser_Object_List(keys_, col_vec_, input_form_, names_col_)))
  , input_form(input_form_)
  { }

  inline void init(r_ssize& length) {
    LOG_DEBUG << length;

    Collector_Base::init(length);
    r_obj* ptype = (*this->parser_ptr).get_ptype();
    set_list_of_attributes(this->data, ptype);
  }

  inline void add_value(r_obj* value, Path& path) {
    LOG_DEBUG;

    if (value == r_null) {
      r_list_poke(this->data, this->current_row++, R_NilValue);
    } else {
      path.down();
      r_list_poke(this->data, this->current_row++, (*this->parser_ptr).parse(value, path));
      path.up();
    }
  }
};

std::pair<r_obj*, std::vector<Collector_Ptr>> parse_fields_spec(cpp11::list spec_list,
                                                              bool vector_allows_empty_list,
                                                              std::string input_form) {
  LOG_DEBUG;

  cpp11::writable::strings keys;
  std::vector<Collector_Ptr> col_vec;

  for (const cpp11::list& elt : spec_list) {
    cpp11::r_string key =  cpp11::strings(elt["key"])[0];
    keys.push_back(key);
    cpp11::r_string type = cpp11::strings(elt["type"])[0];

    if (type == "sub") {
      cpp11::list sub_spec = elt["spec"];
      auto spec_pair = parse_fields_spec(sub_spec, vector_allows_empty_list, input_form);
      col_vec.push_back(Collector_Ptr(new Collector_Same_Key(spec_pair.first, spec_pair.second)));
      continue;
    }

    cpp11::r_string name = cpp11::strings(elt["name"])[0];
    int location = cpp11::integers(elt["location"])[0];
    cpp11::r_bool required = cpp11::logicals(elt["required"])[0];

    if (type == "row") {
      cpp11::list fields = elt["fields"];
      auto spec_pair = parse_fields_spec(fields, vector_allows_empty_list, input_form);
      col_vec.push_back(Collector_Ptr(new Collector_Tibble(spec_pair.first, spec_pair.second, required, location, name)));
      continue;
    } else if (type == "df") {
      cpp11::list fields = elt["fields"];
      auto spec_pair = parse_fields_spec(fields, vector_allows_empty_list, input_form);

      cpp11::sexp names_col = elt["names_col"];
      if (names_col != r_null) {
        names_col = cpp11::strings(names_col)[0];
      }

      col_vec.push_back(
        Collector_Ptr(
          new Collector_List_Of_Tibble(spec_pair.first, spec_pair.second, names_col, required, location, name, input_form)
        )
      );
      continue;
    }

    Field_Args field_args = Field_Args(elt["fill"], elt["transform"]);

    if (type == "unspecified") {
      col_vec.push_back(Collector_Ptr(new Collector_List(required, location, name, field_args)));
      continue;
    }
    if (type == "variant") {
      col_vec.push_back(Collector_Ptr(new Collector_List(required, location, name, field_args, elt["elt_transform"])));
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
        col_vec.push_back(Collector_Ptr(new Collector_Scalar2<r_obj*, cpp11::r_string>(required, location, name, field_args)));
      } else {
        cpp11::sexp na = elt["na"];
        col_vec.push_back(Collector_Ptr(new Collector_Scalar(required, location, name, field_args, na)));
      }
    } else if (type == "vector") {
      cpp11::r_string input_form = cpp11::strings(elt["input_form"])[0];
      Vector_Args vector_args = Vector_Args(
        string_to_form_enum(input_form),
        vector_allows_empty_list,
        elt["names_to"],
        elt["values_to"],
        elt["na"],
        elt["elt_transform"]
      );

      col_vec.push_back(Collector_Ptr(new Collector_Vector(required, location, name, field_args, vector_args))
      );
    } else {
      cpp11::stop("Internal Error: Unsupported type"); // # nocov
    }
  }

  return std::pair<r_obj*, std::vector<Collector_Ptr>>({keys, std::move(col_vec)});
}


[[cpp11::register]]
r_obj* tibblify_impl(r_obj* object_list, r_obj* spec, cpp11::external_pointer<Path> path_ptr) {
  LOG_DEBUG;
  Path &path = *path_ptr;

  cpp11::list spec_list = spec;
  cpp11::r_string type = cpp11::strings(spec_list["type"])[0];

  bool vector_allows_empty_list = cpp11::r_bool(cpp11::logicals(spec_list["vector_allows_empty_list"])[0]);
  std::string input_form = cpp11::r_string(cpp11::strings(spec_list["input_form"])[0]);
  auto spec_pair = parse_fields_spec(spec_list["fields"], vector_allows_empty_list, input_form);

  if (type == "df") {
    cpp11::sexp names_col = spec_list["names_col"];
    if (names_col != r_null) {
      names_col = cpp11::strings(names_col)[0];
    }
    LOG_DEBUG << "============ create parser ============";
    auto parser = Parser_Object_List(spec_pair.first, spec_pair.second, input_form, names_col);

    LOG_DEBUG << "============ parse ============";
    return parser.parse(object_list, path);
  } else if (type == "row" || type == "object") {
    LOG_DEBUG << "============ create parser ============";
    auto parser = Parser_Object(spec_pair.first, spec_pair.second);

    // `path.up()` is needed because `parse()` assumes a list of objects and
    // directly uses `path.down()`
    LOG_DEBUG << "============ parse ============";
    path.up();
    return parser.parse(object_list, path);
  } else {
    cpp11::stop("Internal Error: Unexpected type"); // # nocov
  }
}

// # nocov start
[[cpp11::register]]
void init_logging(const std::string& log_level) {
  plog::init_r(log_level);
}
// # nocov end
