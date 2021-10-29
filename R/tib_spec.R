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
spec_df <- function(..., .names_to = NULL) {
  if (!is_null(.names_to)) {
    vec_assert(.names_to, character(), 1L, arg = ".names_to")
  }
  out <- spec_tib(list2(...), "df", names_col = .names_to)
  if (!is_null(.names_to) && .names_to %in% names(out$fields)) {
    abort("The column name of `.names_to` is already specified in `...`")
  }

  out
}

#' @rdname spec_df
#' @export
spec_object <- function(...) {
  spec_tib(list2(...), "object")
}

#' @rdname spec_df
#' @export
spec_row <- function(...) {
  spec_tib(list2(...), "row")
}

spec_tib <- function(fields, type, ...) {
  structure(
    list(
      type = type,
      fields = prep_spec_fields(fields),
      ...
    ),
    class = c(paste0("spec_", type), "spec_tib")
  )
}

prep_spec_fields <- function(fields) {
  fields <- flatten_fields(fields)

  collector_field <- purrr::map_lgl(fields, ~ inherits(.x, "tib_collector"))
  if (!all(collector_field)) {
    abort("Every element in `...` must be a tib collector.")
  }
  vec_as_names(names2(fields), repair = "check_unique")

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

tib_collector <- function(key, type, ..., required = TRUE, class = NULL) {
  check_key(key)
  check_required(required)

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
tib_unspecified <- function(key, required = TRUE) {
  tib_collector(
    key = key,
    type = "list",
    required = required,
    default_value = NULL,
    transform = NULL,
    class = "tib_unspecified"
  )
}


# scalar fields -----------------------------------------------------------

tib_scalar_impl <- function(key, ptype, required = TRUE, default = NULL, transform = NULL) {
  ptype <- vec_ptype(ptype)
  if (is_null(default)) {
    default <- vec_init(ptype)
  } else {
    vec_assert(default, size = 1L)
    ptype <- vec_cast(default, ptype)
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
    default_value = default,
    transform = prep_transform(transform),
    class = class
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
#' @param required,.required Throw an error if the field does not exist?
#' @param default Default value to use if the field does not exist.
#' @param transform A function to apply to the field before casting to `ptype`.
#' @inheritParams spec_df
#'
#' @details There are basically five different `tib_*()` functions
#'
#' * `tib_scalar(ptype)`: Cast the field to a length one vector of type `ptype`.
#' * `tib_vector(ptype)`: Cast the field to an arbitrary length vector of type `ptype`.
#' * `tib_list()`: Cast the field to a list.
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
#' tib_int("int", FALSE, default = 0)
#'
#' tib_scalar("date", Sys.Date(), transform = function(x) as.Date(x, format = "%Y-%m-%d"))
#'
#' tib_df(
#'   "data",
#'   .names_to = "id",
#'   age = tib_int("age"),
#'   name = tib_chr("name")
#' )
tib_scalar <- function(key, ptype, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(
    key = key,
    required = required,
    ptype = ptype,
    default = default,
    transform = prep_transform(transform)
  )
}

#' @rdname tib_scalar
#' @export
tib_lgl <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = logical(), required = required, default = default, transform = transform)
}

#' @rdname tib_scalar
#' @export
tib_int <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = integer(), required = required, default = default, transform = transform)
}

#' @rdname tib_scalar
#' @export
tib_dbl <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = double(), required = required, default = default, transform = transform)
}

#' @rdname tib_scalar
#' @export
tib_chr <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = character(), required = required, default = default, transform = transform)
}


# vector fields -----------------------------------------------------------

tib_vector_impl <- function(key, ptype, required = TRUE, default = NULL, transform = NULL) {
  ptype <- vec_ptype(ptype)
  if (is_null(default)) {
    default <- ptype
  } else {
    default <- vec_cast(default, ptype)
  }

  class <- NULL
  if (tib_has_special_scalar(ptype)) {
    class <- paste0("tib_vector_", vec_ptype_full(ptype))
  }

  tib_collector(
    key = key,
    type = "vector",
    required = required,
    ptype = ptype,
    default_value = default,
    transform = prep_transform(transform),
    class = class
  )
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
tib_vector <- function(key, ptype, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(
    key = key,
    required = required,
    ptype = ptype,
    default = default,
    transform = transform
  )
}

#' @rdname tib_scalar
#' @export
tib_lgl_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = logical(), required = required, default = default, transform = transform)
}

#' @rdname tib_scalar
#' @export
tib_int_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = integer(), required = required, default = default, transform = transform)
}

#' @rdname tib_scalar
#' @export
tib_dbl_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = double(), required = required, default = default, transform = transform)
}

#' @rdname tib_scalar
#' @export
tib_chr_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = character(), required = required, default = default, transform = transform)
}


# other fields ------------------------------------------------------------

#' @rdname tib_scalar
#' @export
tib_list <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_collector(
    key = key,
    type = "list",
    required = required,
    default_value = default,
    transform = prep_transform(transform)
  )
}

#' @rdname tib_scalar
#' @export
tib_row <- function(.key, ..., .required = TRUE) {
  tib_collector(
    key = .key,
    type = "row",
    required = .required,
    fields = prep_spec_fields(list2(...))
  )
}

#' @rdname tib_scalar
#' @export
tib_df <- function(.key, ..., .required = TRUE, .names_to = NULL) {
  tib_collector(
    key = .key,
    type = "df",
    required = .required,
    fields = prep_spec_fields(list2(...)),
    names_col = .names_to
  )
}


# helpers -----------------------------------------------------------------

prep_transform <- function(f) {
  if (is_null(f)) {
    return(f)
  }

  as_function(f)
}

check_key <- function(key) {
  if (is.character(key)) {
    return()
  }

  if (is.integer(key)) {
    return()
  }

  if (!is.list(key)) {
    abort("`key` must be a character, integer or a list.")
  }

  valid_elt <- purrr::map_lgl(key, ~ is_scalar_character(.x) || is_scalar_integer(.x))
  if (!all(valid_elt)) {
    abort("Every element of `key` must be a scalar character or scalar integer.")
  }
}

check_required <- function(required) {
  vec_assert(required, logical(), 1L)
}
