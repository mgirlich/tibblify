#' Create a Tibblify Specification
#'
#' @export
spec_df <- function(..., .names_to = NULL) {
  spec_tib(list2(...), "df", names_col = .names_to)
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
      if (inherits(x, "spec_row") || inherits(x, "spec_df")) {
        x$fields
      } else {
        list(x)
      }
    }
  )
  vctrs::vec_c(!!!fields_nested, .name_spec = "{inner}")
}

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

tib_scalar_impl <- function(key, ptype, required = TRUE, default = NULL, transform = NULL, class = NULL) {
  ptype <- vec_ptype(ptype)
  if (is_null(default)) {
    default <- vec_init(ptype)
  } else {
    vec_assert(default, size = 1L)
    ptype <- vec_cast(default, ptype)
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

#' @export
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
  tib_scalar_impl(key, ptype = logical(), required = required, default = default, transform = transform, class = "tib_scalar_lgl")
}

#' @rdname tib_scalar
#' @export
tib_int <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = integer(), required = required, default = default, transform = transform, class = "tib_scalar_int")
}

#' @rdname tib_scalar
#' @export
tib_dbl <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = double(), required = required, default = default, transform = transform, class = "tib_scalar_dbl")
}

#' @rdname tib_scalar
#' @export
tib_chr <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_scalar_impl(key, ptype = character(), required = required, default = default, transform = transform, class = "tib_scalar_chr")
}

tib_vector_impl <- function(key, ptype, required = TRUE, default = NULL, transform = NULL, class = NULL) {
  ptype <- vec_ptype(ptype)
  if (is_null(default)) {
    default <- ptype
  } else {
    default <- vec_cast(default, ptype)
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
  tib_vector_impl(key, ptype = logical(), required = required, default = default, transform = transform, class = "tib_vector_lgl")
}

#' @rdname tib_scalar
#' @export
tib_int_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = integer(), required = required, default = default, transform = transform, class = "tib_vector_int")
}

#' @rdname tib_scalar
#' @export
tib_dbl_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = double(), required = required, default = default, transform = transform, class = "tib_vector_dbl")
}

#' @rdname tib_scalar
#' @export
tib_chr_vec <- function(key, required = TRUE, default = NULL, transform = NULL) {
  tib_vector_impl(key, ptype = character(), required = required, default = default, transform = transform, class = "tib_vector_chr")
}

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
