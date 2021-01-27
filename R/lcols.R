#' Create list parser specification
#'
#' @param ... Column specification objects created by `lcol_*()`.
#' @param .default The default parser to use.
#'
#' @export
#' @examples
#' lcols(
#'   lcol_int("id"),
#'   lcol_chr("name"),
#'   lcol_lst_of("aliases", character())
#' )
#'
#' # To create multiple columns of the same type use the bang-bang-bang (!!!)
#' # operator together with `purrr::map()`
#' lcols(
#'   !!!purrr::map(c("id", "age"), lcol_int),
#'   !!!purrr::map(c("name", "title"), lcol_chr),
#'   !!!purrr::map(c("aliases", "addresses"), lcol_guess)
#' )
lcols <- function(..., .default = lcol_skip(zap())) {
  if (!is_lcollector(.default)) {
    abort("`.default` must be a lcollector")
  }

  pluckers <- check_pluckers(...)

  if (is_empty(pluckers) && is_skip_col(.default)) {
    abort("must provide columns or not set `.default = zap()`")
  }

  new_lcol_spec(pluckers, .default)
}


check_pluckers <- function(...) {
  pluckers <- list2(...)

  if (is_empty(pluckers)) {
    return(pluckers)
  }

  is_lcollector_flag <- vapply(pluckers, is_lcollector, logical(1))
  if (!all(is_lcollector_flag)) {
    abort("All elements of `...` must be pluckers")
  }

  # if unnamed, use path as name
  auto_names <- lapply(
    pluckers,
    function(x) {
      path <- x[["path"]]
      path[length(path)]
    }
  )
  use_auto_name <- names2(pluckers) == "" &
    vapply(auto_names, is_string, logical(1))

  if (any(use_auto_name)) {
    names(pluckers)[use_auto_name] <- auto_names[use_auto_name]
  }

  if (!is_named(pluckers)) {
    abort("All elements of `...` must be named")
  }

  names(pluckers) <- vec_as_names(names(pluckers), repair = "check_unique")

  # attr(dots, "auto_name") <- empty_name_flag

  pluckers
}


new_lcol_spec <- function(cols, .default = zap()) {
  structure(
    list(
      .default = .default,
      cols = cols
    ),
    class = "lcol_spec"
  )
}


set_spec <- function(x, spec) {
  attr(x, "spec") <- spec
  x
}


#' Examine the column specification
#'
#' @param x The data frame object to extract from
#'
#' @export
get_spec <- function(x) {
  attr(x, "spec")
}
