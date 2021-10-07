#' @noRd
#' @param x A list
#' @param transform A function or formula; passed to [`rlang::as_function()`]
apply_transform <- function(x, transform = NULL) {
  if (is.null(transform)) {
    return(x)
  }

  transform <- as_function(transform)
  purrr::map(x, transform)
}

#' Simplify a list to a vector
#'
#' @param x List to simplify
#' @param ptype Prototype of the simplified result
#' @param transform A transformation applied to every element before casting.
#'
#' @return A vector the same length as `x` with the same type as `ptype`.
#'
#' @noRd
#' @examples
#' simplify_vector(as.list(1:3), double())
#' simplify_vector(
#'   list("2020-07-01"),
#'   Sys.Date(),
#'   transform = ~ as.Date.character(.x, format = "%Y-%m-%d")
#' )
simplify_vector <- function(x, ptype, transform = NULL) {
  vctrs::vec_assert(x, list())
  if (is.null(ptype)) {
    abort("`ptype` must not be `NULL`.")
  }

  x <- apply_transform(x, transform)

  sizes <- list_sizes(x)
  bad_size <- sizes != 1L
  if (any(bad_size)) {
    # TODO mention path and (some) positions
    abort("Not all elements of `x` have size 1.")
  }

  vec_c(!!!x, .ptype = ptype)
}

simplify_list_of <- function(x, ptype, transform = NULL) {
  vctrs::vec_assert(x, list())
  if (is.null(ptype)) {
    abort("`ptype` must not be `NULL`.")
  }

  x <- apply_transform(x, transform)
  out <- new_list_of(x, ptype = vec_ptype(ptype))

  vctrs::validate_list_of(out)
}
