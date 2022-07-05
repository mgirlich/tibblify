#' Create a Tibblify Specification
#'
#' Use `spec_df()` to specify how to convert a list of objects to a tibble.
#' Use `spec_row()` resp. `spec_object()` to specify how to convert an object
#' to a one row tibble resp. a list.
#'
#' @param ... Column specification created by `tib_*()` or `spec_*()`.
#' @param .names_to A string giving the name of the column which will contain
#'   the names of elements of the object list. If `NULL`, the default, no name
#'   column is created
#' @param vector_allows_empty_list Should empty lists for `input_form = "vector"`
#'   be accepted and treated as empty vector?
#'
#' @export
#' @examples
#' spec_df(
#'   id = tib_int("id"),
#'   name = tib_chr("name"),
#'   aliases = tib_chr_vec("aliases")
#' )
#'
#' # To create multiple columns of the same type use the bang-bang-bang (!!!)
#' # operator together with `purrr::map()`
#' spec_df(
#'   !!!purrr::map(purrr::set_names(c("id", "age")), tib_int),
#'   !!!purrr::map(purrr::set_names(c("name", "title")), tib_chr)
#' )
#'
#' # The `spec_*()` functions can also be nested
#' spec1 <- spec_object(
#'   int = tib_int("int"),
#'   chr = tib_chr("chr")
#' )
#' spec2 <- spec_object(
#'   int2 = tib_int("int2"),
#'   chr2 = tib_chr("chr2")
#' )
#'
#' spec_df(spec1, spec2)
spec_df <- function(..., .names_to = NULL, vector_allows_empty_list = FALSE) {
  if (!is_null(.names_to)) {
    check_string(.names_to, what = "a single string or `NULL`")
  }

  out <- spec_tib(
    list2(...),
    "df",
    names_col = .names_to,
    vector_allows_empty_list = vector_allows_empty_list
  )
  if (!is_null(.names_to) && .names_to %in% names(out$fields)) {
    msg <- "The column name of {.arg .names_to} is already specified in {.arg ...}."
    cli::cli_abort(msg)
  }

  out
}

#' @rdname spec_df
#' @export
spec_object <- function(..., vector_allows_empty_list = FALSE) {
  spec_tib(
    list2(...),
    "object",
    vector_allows_empty_list = vector_allows_empty_list
  )
}

#' @rdname spec_df
#' @export
spec_row <- function(..., vector_allows_empty_list = FALSE) {
  spec_tib(
    list2(...),
    "row",
    vector_allows_empty_list = vector_allows_empty_list
  )
}

spec_tib <- function(fields, type, ..., vector_allows_empty_list = FALSE, call = caller_env()) {
  check_bool(vector_allows_empty_list)

  structure(
    list2(
      type = type,
      fields = prep_spec_fields(fields, call),
      ...,
      vector_allows_empty_list = vector_allows_empty_list
    ),
    class = c(paste0("spec_", type), "spec_tib")
  )
}

prep_spec_fields <- function(fields, call) {
  fields <- flatten_fields(fields)
  if (is_null(fields)) {
    return(list())
  }

  bad_idx <- purrr::detect_index(fields, ~ !inherits(.x, "tib_collector"))
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
      if (inherits(x, "spec_tib")) {
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

  structure(
    list(
      type = type,
      key = key,
      required = required,
      ...
    ),
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
                            call = caller_env()) {
  check_dots_empty()
  ptype <- vec_ptype(ptype, x_arg = "ptype", call = call)
  ptype_inner <- vec_ptype(ptype_inner, x_arg = "ptype_inner", call = call)
  if (is_null(fill)) {
    fill <- vec_init(ptype_inner)
  } else {
    vec_assert(fill, size = 1L, call = call)
    fill <- vec_cast(fill, ptype_inner, call = call, to_arg = "ptype_inner")
  }

  class <- NULL
  if (tib_has_special_scalar(ptype)) {
    class <- paste0("tib_scalar_", vec_ptype_full(ptype))
  }

  tib_collector(
    key = key,
    type = "scalar",
    required = required,
    ptype = ptype,
    ptype_inner = ptype_inner,
    fill = fill,
    transform = prep_transform(transform, call),
    class = class,
    call = call
  )
}

tib_has_special_scalar <- function(ptype) {
  UseMethod("tib_has_special_scalar")
}

#' @export
tib_has_special_scalar.default <- function(ptype) FALSE
#' @export
tib_has_special_scalar.logical <- function(ptype) vec_is(ptype, logical())
#' @export
tib_has_special_scalar.integer <- function(ptype) vec_is(ptype, integer())
#' @export
tib_has_special_scalar.double <- function(ptype) vec_is(ptype, double())
#' @export
tib_has_special_scalar.character <- function(ptype) vec_is(ptype, character())

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
#' @inheritParams spec_df
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
                            call = caller_env()) {
  check_dots_empty()
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

  class <- NULL
  if (tib_has_special_scalar(ptype)) {
    class <- paste0("tib_vector_", vec_ptype_full(ptype))
  }

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

tib_has_special_vector <- function(ptype) {
  UseMethod("tib_has_special_vector")
}

#' @export
tib_has_special_vector.default <- function(ptype) FALSE
#' @export
tib_has_special_vector.logical <- function(ptype) vec_is(ptype, logical())
#' @export
tib_has_special_vector.integer <- function(ptype) vec_is(ptype, integer())
#' @export
tib_has_special_vector.double <- function(ptype) vec_is(ptype, double())
#' @export
tib_has_special_vector.character <- function(ptype) vec_is(ptype, character())

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
    if (key == "") {
      cli::cli_abort("{.arg key} must not be an empty string.", call = call)
    }

    if (is.na(key)) {
      cli::cli_abort("{.arg key} must not be {.val NA}.", call = call)
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
