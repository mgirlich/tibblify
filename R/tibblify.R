#' Rectangle a nested list
#'
#' @param x A nested list.
#' @param spec A specification how to convert `x`. Generated with `spec_row()`
#'   or `spec_df()`.
#' @param names_to Deprecated. Use `spec_df(.names_to)` instead.
#'
#' @return Either a tibble or a list, depending on the specification
#' @export
#'
#' @examples
#' x <- list(
#'   list(id = 1, name = "Tyrion Lannister"),
#'   list(id = 2, name = "Victarion Greyjoy")
#' )
#' tibblify(x)
#'
#' # Provide a specification
#' spec <- spec_df(
#'   id = tib_int("id"),
#'   name = tib_chr("name")
#' )
#' tibblify(x, spec)
#'
#' # Provide a specification for a single object
#' tibblify(x[[1]], spec_object(spec))
tibblify <- function(x, spec = NULL, names_to = NULL) {
  if (!is.null(names_to)) {
    lifecycle::deprecate_stop("0.2.0", "tibblify(names_to)")
  }

  if (is_null(spec)) {
    spec <- guess_shape(x)
  }

  spec$fields <- spec_prep(spec$fields, !is.null(spec$names_col))
  out <- tibblify_impl(x, spec)

  if (inherits(spec, "spec_object")) {
    # TODO need custom class so that `spec` attribute isn't always printed
    out <- finalize_object(out)
  }

  out
}

finalize_object <- function(x) {
  UseMethod("finalize_object")
}

#' @export
finalize_object.default <- function(x) {
  x[[1]]
}

#' @export
finalize_object.data.frame <- function(x) {
  purrr::map(x, finalize_object)
}

spec_prep <- function(spec, shift = FALSE) {
  for (i in seq_along(spec)) {
    spec[[i]]$location <- i - 1L + as.integer(shift)
    spec[[i]]$name <- names(spec)[[i]]
  }

  prep_nested_keys(spec)
}

prep_nested_keys <- function(spec, shift = FALSE) {
  remove_first_key <- function(x) {
    x$key <- x$key[-1]
    x
  }

  is_sub <- purrr::map_lgl(spec, ~ length(.x$key) > 1)
  spec_simple <- spec[!is_sub]
  spec_simple_prepped <- purrr::map(
    spec_simple,
    function(x) {
      x$key <- unlist(x$key)

      if (x$type == "row" || x$type == "df") {
        x$fields <- spec_prep(x$fields, shift = !is.null(x$names_col))
      }

      x
    }
  )

  spec_complex <- spec[is_sub]

  first_keys <- purrr::map_chr(spec_complex, list("key", 1))
  spec_complex <- purrr::map(spec_complex, remove_first_key)
  spec_split <- vec_split(spec_complex, first_keys)
  spec_complex_prepped <- purrr::map2(
    spec_split$key, spec_split$val,
    function(key, sub_spec) {
      list(
        key = key,
        type = "sub",
        spec = prep_nested_keys(sub_spec)
      )
    }
  )

  c(
    spec_simple_prepped,
    spec_complex_prepped
  )
}

set_spec <- function(x, spec) {
  attr(x, "tib_spec") <- spec
  x
}

#' Examine the column specification
#'
#' @param x The data frame object to extract from
#'
#' @export
get_spec <- function(x) {
  attr(x, "tib_spec")
}
