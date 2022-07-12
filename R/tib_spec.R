#' Create a Tibblify Specification
#'
#' Use `tspec_df()` to specify how to convert a list of objects to a tibble.
#' Use `tspec_row()` resp. `tspec_object()` to specify how to convert an object
#' to a one row tibble resp. a list.
#'
#' @param ... Column specification created by `tib_*()` or `tspec_*()`.
#' @param .input_form The input form of data frame like lists. Can be one of:
#'   * `"rowmajor"`: The default. The data frame is formed by a list of rows.
#'   * `"colmajor"`: The data frame is a named list of columns.
#' @param .names_to A string giving the name of the column which will contain
#'   the names of elements of the object list. If `NULL`, the default, no name
#'   column is created
#' @param vector_allows_empty_list Should empty lists for `input_form = "vector"`
#'   be accepted and treated as empty vector?
#'
#' @export
#' @examples
#' tspec_df(
#'   id = tib_int("id"),
#'   name = tib_chr("name"),
#'   aliases = tib_chr_vec("aliases")
#' )
#'
#' # To create multiple columns of the same type use the bang-bang-bang (!!!)
#' # operator together with `purrr::map()`
#' tspec_df(
#'   !!!purrr::map(purrr::set_names(c("id", "age")), tib_int),
#'   !!!purrr::map(purrr::set_names(c("name", "title")), tib_chr)
#' )
#'
#' # The `tspec_*()` functions can also be nested
#' spec1 <- tspec_object(
#'   int = tib_int("int"),
#'   chr = tib_chr("chr")
#' )
#' spec2 <- tspec_object(
#'   int2 = tib_int("int2"),
#'   chr2 = tib_chr("chr2")
#' )
#'
#' tspec_df(spec1, spec2)
tspec_df <- function(...,
                     .input_form = c("rowmajor", "colmajor"),
                     .names_to = NULL,
                     vector_allows_empty_list = FALSE) {
  .input_form <- arg_match(.input_form)
  check_names_to(.names_to, .input_form)

  out <- tspec(
    list2(...),
    "df",
    input_form = .input_form,
    names_col = .names_to,
    vector_allows_empty_list = vector_allows_empty_list
  )
  if (!is_null(.names_to) && .names_to %in% names(out$fields)) {
    msg <- "The column name of {.arg .names_to} is already specified in {.arg ...}."
    cli::cli_abort(msg)
  }

  out
}

check_names_to <- function(.names_to, input_form, call = caller_env()) {
  if (!is_null(.names_to)) {
    if (input_form == "colmajor") {
      msg <- 'Cannot use {.arg .names_to} for {.code .input_form = "colmajor"}.'
      cli::cli_abort(msg, call = call)
    }
    check_string(.names_to, what = "a single string or `NULL`", call = call)
  }
}

#' @rdname tspec_df
#' @export
tspec_object <- function(...,
                         .input_form = c("rowmajor", "colmajor"),
                         vector_allows_empty_list = FALSE) {
  .input_form <- arg_match(.input_form)
  tspec(
    list2(...),
    "object",
    input_form = .input_form,
    vector_allows_empty_list = vector_allows_empty_list
  )
}

#' @rdname tspec_df
#' @export
tspec_row <- function(...,
                      .input_form = c("rowmajor", "colmajor"),
                      vector_allows_empty_list = FALSE) {
  .input_form <- arg_match(.input_form)
  tspec(
    list2(...),
    "row",
    input_form = .input_form,
    vector_allows_empty_list = vector_allows_empty_list
  )
}

tspec <- function(fields, type, ..., vector_allows_empty_list = FALSE, call = caller_env()) {
  check_bool(vector_allows_empty_list, call = call)

  structure(
    list2(
      type = type,
      fields = prep_spec_fields(fields, call),
      ...,
      vector_allows_empty_list = vector_allows_empty_list
    ),
    class = c(paste0("tspec_", type), "tspec")
  )
}

is_tspec <- function(x) {
  inherits(x, "tspec")
}

prep_spec_fields <- function(fields, call) {
  fields <- flatten_fields(fields)
  if (is_null(fields)) {
    return(list())
  }

  bad_idx <- purrr::detect_index(fields, ~ !is_tib(.x))
  if (bad_idx != 0) {
    name <- names2(fields)[[bad_idx]]
    if (name == "") {
      name <- paste0("..", bad_idx)
    }
    friendly_type <- obj_type_friendly(fields[[bad_idx]])

    msg <- "Element {.field {name}} must be a tib collector, not {friendly_type}."
    cli::cli_abort(msg, call = call)
  }

  spec_auto_name_fields(fields, call)
}

spec_auto_name_fields <- function(fields, call) {
  field_nms <- names2(fields)
  unnamed <- !have_name(fields)
  auto_nms <- purrr::map2_chr(
    fields[unnamed],
    seq_along(fields)[unnamed],
    ~ {
      key <- .x$key
      if (!is_string(key)) {
        loc <- paste0("..", .y)
        msg <- c(
          "Can't infer name if key is not a single string",
          x = "{.arg key} of element {.field {loc}} has length {length(key)}."
        )
        cli::cli_abort(msg, call = call)
      }

      key
    }
  )
  field_nms[unnamed] <- auto_nms
  field_nms_repaired <- vec_as_names(field_nms, repair = "check_unique", call = call)
  names(fields) <- field_nms_repaired
  fields
}

flatten_fields <- function(fields) {
  fields_nested <- purrr::map(
    fields,
    function(x) {
      if (is_tspec(x)) {
        x$fields
      } else {
        list(x)
      }
    }
  )
  vctrs::vec_c(!!!fields_nested, .name_spec = "{inner}")
}


# field specifiers --------------------------------------------------------

tib_collector <- function(key,
                          type,
                          ...,
                          required = TRUE,
                          class = NULL,
                          call = caller_env()) {
  check_key(key, call)
  check_required(required, call)

  fields <- list(
    type = type,
    key = key,
    required = required,
    ...
  )

  class <- tib_native_ptype(fields$ptype, class, fields)
  structure(
    fields,
    class = c(class, paste0("tib_", type), "tib_collector")
  )
}

#' @rdname tib_scalar
#' @export
tib_unspecified <- function(key, ..., required = TRUE) {
  check_dots_empty()
  tib_collector(
    key = key,
    type = "unspecified",
    required = required,
    class = "tib_unspecified"
  )
}


# scalar fields -----------------------------------------------------------

tib_scalar_impl <- function(key,
                            ptype,
                            ...,
                            required = TRUE,
                            fill = NULL,
                            ptype_inner = ptype,
                            transform = NULL,
                            class = NULL,
                            call = caller_env()) {
  ptype <- vec_ptype(ptype, x_arg = "ptype", call = call)
  ptype_inner <- vec_ptype(ptype_inner, x_arg = "ptype_inner", call = call)
  if (is_null(fill)) {
    fill <- vec_init(ptype_inner)
  } else {
    vec_assert(fill, size = 1L, call = call)
    fill <- vec_cast(fill, ptype_inner, call = call, to_arg = "ptype_inner")
  }

  tib_collector(
    key = key,
    type = "scalar",
    required = required,
    ptype = ptype,
    ptype_inner = ptype_inner,
    fill = fill,
    transform = prep_transform(transform, call),
    ...,
    class = class,
    call = call
  )
}

tib_native_ptype <- function(ptype, class, fields) {
  if (!is_null(class)) return(class)
  if (!fields$type %in% c("scalar", "vector")) return(NULL)

  UseMethod("tib_native_ptype")
}

#' @export
tib_native_ptype.default <- function(ptype, class, fields) NULL
#' @export
tib_native_ptype.logical <- function(ptype, class, fields) {
  if (!vec_is(ptype, logical())) return(NULL)

  paste0("tib_", fields$type, "_logical")
}
#' @export
tib_native_ptype.integer <- function(ptype, class, fields) {
  if (!vec_is(ptype, integer())) return(NULL)

  paste0("tib_", fields$type, "_integer")
}
#' @export
tib_native_ptype.double <- function(ptype, class, fields) {
  if (!vec_is(ptype, double())) return(NULL)

  paste0("tib_", fields$type, "_double")
}
#' @export
tib_native_ptype.character <- function(ptype, class, fields) {
  if (!vec_is(ptype, character())) return(NULL)

  paste0("tib_", fields$type, "_character")
}
#' @export
tib_native_ptype.Date <- function(ptype, class, fields) {
  if (!vec_is(ptype, vctrs::new_date())) return(NULL)

  paste0("tib_", fields$type, "_date")
}

#' Create a Field Specification
#'
#' Use these functions to specify how to convert the fields of an object.
#'
#' @param key,.key The path to the field in the object.
#' @param ptype A prototype of the desired output type of the field.
#' @param ... These dots are for future extensions and must be empty.
#' @param required,.required Throw an error if the field does not exist?
#' @param fill Optionally, a value to use if the field does not exist.
#' @param ptype_inner A prototype of the field.
#' @param transform A function to apply after casting to `ptype_inner`.
#'   When exactly it is applied depends on the field type:
#'   * `tib_scalar()` it is applied to the column.
#'   * `tib_vector()`, `tib_variant()` it is applied to each element of the column.
#' @param input_form A string that describes what structure the field has. Can
#'   be one of:
#'   * `"vector"`: The field is a vector, e.g. `c(1, 2, 3)`.
#'   * `"scalar_list"`: The field is a list of scalars, e.g. `list(1, 2, 3)`.
#'   * `"object"`: The field is a named list of scalars, e.g. `list(a = 1, b = 2, c = 3)`.
#' @param values_to Can be one of the following:
#'   * `NULL`: the default. The field is converted to a `ptype` vector.
#'   * A string: The field is converted to a tibble and the values go into the
#'     specified column.
#' @param names_to Can be one of the following:
#'   * `NULL`: the default. The inner names of the field are not used.
#'   * A string: This can only be used if 1) for the input form is `"object"`
#'     or `"vector"` and 2) `values_to` is a string. The inner names of the
#'     field go into the specified column.
#' @param format Optional, a string passed to the `format` argument of `as.Date()`.
#' @inheritParams tspec_df
#'
#' @details There are basically five different `tib_*()` functions
#'
#' * `tib_scalar(ptype)`: Cast the field to a length one vector of type `ptype`.
#' * `tib_vector(ptype)`: Cast the field to an arbitrary length vector of type `ptype`.
#' * `tib_variant()`: Cast the field to a list.
#' * `tib_row()`: Cast the field to a named list.
#' * `tib_df()`: Cast the field to a tibble.
#'
#' There are some special shortcuts of `tib_scalar()` resp. `tib_vector()` for
#' the most common prototypes
#'
#' * `logical()`: `tib_lgl()` resp. `tib_lgl_vec()`
#' * `integer()`: `tib_int()` resp. `tib_int_vec()`
#' * `double()`: `tib_dbl()` resp. `tib_dbl_vec()`
#' * `character()`: `tib_chr()` resp. `tib_chr_vec()`
#' * `Date`: `tib_date()` resp. `tib_date_vec()`
#'
#' Further, there is also a special shortcut for dates encoded as character:
#' `tib_chr_date()` resp. `tib_chr_date_vec()`.
#'
#' @export
#'
#' @examples
#' tib_int("int")
#' tib_int("int", required = FALSE, fill = 0)
#'
#' tib_scalar("date", Sys.Date(), transform = function(x) as.Date(x, format = "%Y-%m-%d"))
#'
#' tib_df(
#'   "data",
#'   .names_to = "id",
#'   age = tib_int("age"),
#'   name = tib_chr("name")
#' )
tib_scalar <- function(key,
                       ptype,
                       ...,
                       required = TRUE,
                       fill = NULL,
                       ptype_inner = ptype,
                       transform = NULL) {
  check_dots_empty()
  tib_scalar_impl(
    key = key,
    required = required,
    ptype = ptype,
    ptype_inner = ptype_inner,
    fill = fill,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_lgl <- function(key,
                    ...,
                    required = TRUE,
                    fill = NULL,
                    ptype_inner = logical(),
                    transform = NULL) {
  check_dots_empty()
  tib_scalar_impl(
    key,
    ptype = logical(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_int <- function(key,
                    ...,
                    required = TRUE,
                    fill = NULL,
                    ptype_inner = integer(),
                    transform = NULL) {
  check_dots_empty()
  tib_scalar_impl(
    key,
    ptype = integer(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_dbl <- function(key,
                    ...,
                    required = TRUE,
                    fill = NULL,
                    ptype_inner = double(),
                    transform = NULL) {
  check_dots_empty()
  tib_scalar_impl(
    key,
    ptype = double(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_chr <- function(key,
                    ...,
                    required = TRUE,
                    fill = NULL,
                    ptype_inner = character(),
                    transform = NULL) {
  check_dots_empty()
  tib_scalar_impl(
    key,
    ptype = character(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_date <- function(key,
                     ...,
                     required = TRUE,
                     fill = NULL,
                     ptype_inner = vctrs::new_date(),
                     transform = NULL) {
  check_dots_empty()
  tib_scalar_impl(
    key,
    ptype = vctrs::new_date(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_chr_date <- function(key,
                         ...,
                         required = TRUE,
                         fill = NULL,
                         format = "%Y-%m-%d") {
  check_dots_empty()
  tib_scalar_impl(
    key,
    ptype = vctrs::new_date(),
    required = required,
    fill = fill,
    ptype_inner = character(),
    format = format,
    transform = ~ as.Date(.x, format = format),
    class = "tib_scalar_chr_date"
  )
}

# vector fields -----------------------------------------------------------

tib_vector_impl <- function(key,
                            ptype,
                            ...,
                            required = TRUE,
                            fill = NULL,
                            ptype_inner = ptype,
                            transform = NULL,
                            input_form = c("vector", "scalar_list", "object"),
                            values_to = NULL,
                            names_to = NULL,
                            class = NULL,
                            call = caller_env()) {
  input_form <- arg_match0(
    input_form,
    c("vector", "scalar_list", "object"),
    error_call = call
  )
  ptype <- vec_ptype(ptype, call = call, x_arg = "ptype")
  ptype_inner <- vec_ptype(ptype_inner, call = call, x_arg = "ptype_inner")
  if (!is_null(fill)) {
    fill <- vec_cast(fill, ptype, call = call, to_arg = "ptype")
  }
  values_to <- tib_check_values_to(values_to, call)
  names_to <- tib_check_names_to(names_to, values_to, input_form, call)

  tib_collector(
    key = key,
    type = "vector",
    required = required,
    ptype = ptype,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = prep_transform(transform, call),
    input_form = input_form,
    values_to = values_to,
    names_to = names_to,
    ...,
    class = class,
    call = call
  )
}

tib_check_values_to <- function(values_to, call) {
  if (!is_null(values_to)) {
    check_string(values_to, call = call)
  }

  values_to
}

tib_check_names_to <- function(names_to, values_to, input_form, call) {
  if (!is_null(names_to)) {
    if (is_null(values_to)) {
      msg <- "{.arg names_to} can only be used if {.arg values_to} is not {.code NULL}."
      cli::cli_abort(msg, call = call)
    }
    if (input_form == "scalar_list") {
      msg <- '{.arg names_to} can\'t be used for {.code input_form = "scalar_list"}.'
      cli::cli_abort(msg, call = call)
    }

    check_string(names_to, call = call)
    vec_assert(names_to, size = 1, call = call)
    if (names_to == values_to) {
      msg <- "{.arg names_to} must be different from {.arg values_to}."
      cli::cli_abort(msg, call = call)
    }
  }

  names_to
}

#' @rdname tib_scalar
#' @export
tib_vector <- function(key,
                       ptype,
                       ...,
                       required = TRUE,
                       fill = NULL,
                       ptype_inner = ptype,
                       transform = NULL,
                       input_form = c("vector", "scalar_list", "object"),
                       values_to = NULL,
                       names_to = NULL) {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key = key,
    required = required,
    ptype = ptype,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform,
    input_form = input_form,
    values_to = values_to,
    names_to = names_to
  )
}

#' @rdname tib_scalar
#' @export
tib_lgl_vec <- function(key,
                        ...,
                        required = TRUE,
                        fill = NULL,
                        ptype_inner = logical(),
                        transform = NULL,
                        input_form = c("vector", "scalar_list", "object"),
                        values_to = NULL,
                        names_to = NULL) {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key,
    ptype = logical(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform,
    input_form = input_form,
    values_to = values_to,
    names_to = names_to
  )
}

#' @rdname tib_scalar
#' @export
tib_int_vec <- function(key,
                        ...,
                        required = TRUE,
                        fill = NULL,
                        ptype_inner = integer(),
                        transform = NULL,
                        input_form = c("vector", "scalar_list", "object"),
                        values_to = NULL,
                        names_to = NULL) {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key,
    ptype = integer(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform,
    input_form = input_form,
    values_to = values_to,
    names_to = names_to
  )
}

#' @rdname tib_scalar
#' @export
tib_dbl_vec <- function(key,
                        ...,
                        required = TRUE,
                        fill = NULL,
                        ptype_inner = double(),
                        transform = NULL,
                        input_form = c("vector", "scalar_list", "object"),
                        values_to = NULL,
                        names_to = NULL) {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key,
    ptype = double(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform,
    input_form = input_form,
    values_to = values_to,
    names_to = names_to
  )
}

#' @rdname tib_scalar
#' @export
tib_chr_vec <- function(key,
                        ...,
                        required = TRUE,
                        fill = NULL,
                        ptype_inner = character(),
                        transform = NULL,
                        input_form = c("vector", "scalar_list", "object"),
                        values_to = NULL,
                        names_to = NULL) {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key,
    ptype = character(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform,
    input_form = input_form,
    values_to = values_to,
    names_to = names_to
  )
}

#' @rdname tib_scalar
#' @export
tib_date_vec <- function(key,
                         ...,
                         required = TRUE,
                         fill = NULL,
                         ptype_inner = vctrs::new_date(),
                         transform = NULL,
                         input_form = c("vector", "scalar_list", "object"),
                         values_to = NULL,
                         names_to = NULL) {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key,
    ptype = vctrs::new_date(),
    required = required,
    fill = fill,
    ptype_inner = ptype_inner,
    transform = transform,
    input_form = input_form,
    values_to = values_to,
    names_to = names_to
  )
}

#' @rdname tib_scalar
#' @export
tib_chr_date_vec <- function(key,
                             ...,
                             required = TRUE,
                             fill = NULL,
                             input_form = c("vector", "scalar_list", "object"),
                             values_to = NULL,
                             names_to = NULL,
                             format = "%Y-%m-%d") {
  check_dots_empty()
  input_form <- arg_match0(input_form, c("vector", "scalar_list", "object"))
  tib_vector_impl(
    key,
    ptype = vctrs::new_date(),
    required = required,
    fill = fill,
    ptype_inner = character(),
    format = format,
    transform = ~ as.Date(.x, format = format),
    input_form = input_form,
    values_to = values_to,
    names_to = names_to,
    class = "tib_vector_chr_date"
  )
}


# other fields ------------------------------------------------------------

#' @rdname tib_scalar
#' @export
tib_variant <- function(key,
                        ...,
                        required = TRUE,
                        fill = NULL,
                        transform = NULL) {
  check_dots_empty()
  tib_collector(
    key = key,
    type = "variant",
    required = required,
    fill = fill,
    transform = prep_transform(transform, call = current_env())
  )
}

#' @rdname tib_scalar
#' @export
tib_row <- function(.key, ..., .required = TRUE) {
  tib_collector(
    key = .key,
    type = "row",
    required = .required,
    fields = prep_spec_fields(list2(...), call = current_env())
  )
}

#' @rdname tib_scalar
#' @export
tib_df <- function(.key, ..., .required = TRUE, .names_to = NULL) {
  if (!is_null(.names_to)) {
    check_string(.names_to)
  }

  tib_collector(
    key = .key,
    type = "df",
    required = .required,
    fields = prep_spec_fields(list2(...), call = current_env()),
    names_col = .names_to
  )
}


# helpers -----------------------------------------------------------------

is_tib <- function(x) {
  inherits(x, "tib_collector")
}

is_tib_unspecified <- function(x) {
  inherits(x, "tib_unspecified")
}

is_tib_scalar <- function(x) {
  inherits(x, "tib_scalar")
}

is_tib_vector <- function(x) {
  inherits(x, "tib_vector")
}

is_tib_variant <- function(x) {
  inherits(x, "tib_variant")
}

is_tib_row <- function(x) {
  inherits(x, "tib_row")
}

is_tib_df <- function(x) {
  inherits(x, "tib_df")
}

prep_transform <- function(f, call) {
  if (is_null(f)) {
    return(f)
  }

  as_function(f, arg = "transform", call = call)
}

check_key <- function(key, call = caller_env()) {
  check_character(key, call = call)

  n <- vec_size(key)
  if (n == 0) {
    cli::cli_abort("{.arg key} must not be empty.", call = call)
  }

  if (n == 1) {
    if (is.na(key)) {
      cli::cli_abort("{.arg key} must not be {.val NA}.", call = call)
    }

    if (key == "") {
      cli::cli_abort("{.arg key} must not be an empty string.", call = call)
    }
  }

  na_idx <- purrr::detect_index(vec_equal_na(key), ~ .x)
  if (na_idx != 0) {
    msg <- "`key[{.field {na_idx}}] must not be NA."
    cli::cli_abort(msg, call = call)
  }

  empty_string_idx <- purrr::detect_index(key == "", ~ .x)
  if (empty_string_idx != 0) {
    msg <- "`key[{.field {empty_string_idx}}] must not be an empty string."
    cli::cli_abort(msg, call = call)
  }
}

check_required <- function(required, call) {
  check_bool(required, call = call)
}
