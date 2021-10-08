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
lcols <- function(..., .default = zap()) {
  lifecycle::deprecate_warn("0.2.0", "lcols()", "spec_df()")
  if (!is_zap(.default)) {
    lifecycle::deprecate_stop("0.2.0", "lcols(.default)")
  }

  spec_df(...)
}
