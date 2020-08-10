#' Simplify a list
#'
#' @param x List to simplify.
#' @param ptype Prototype of the simplified result
#' @param transform A transformation applied to every element before casting.
#'
#' @return A vector the same length as `x` with the same type as `ptype`.
#'
#' @noRd
#' @examples
#' simplify_col(as.list(1:3), double())
#' simplify_col(
#'   list("2020-07-01"),
#'   Sys.Date(),
#'   transform = ~ as.Date.character(.x, format = "%Y-%m-%d")
#' )
simplify_col <- function(x, ptype, transform = NULL) {
  stopifnot(is.list(x))
  stopifnot(!is.null(ptype))

  if (!is.null(transform)) {
    transform <- as_function(transform)
    x <- purrr::map(x, transform)
  }

  if (is_list_of(ptype)) {
    new_list_of(x, ptype = attr(ptype, "ptype"))
  } else if (vec_is_list(ptype)) {
    vec_cast(x, to = ptype)
  } else {
    if (any(purrr::map_lgl(x, vec_is_list))) {
      stop("x contains list elements")
    }

    if (any(list_sizes(x) > 1)) {
      stop("x contains list elements")
    }
    vec_c(!!!x, .ptype = ptype)
  }
}
