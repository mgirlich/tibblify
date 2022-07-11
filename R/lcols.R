#' Create list parser specification
#'
#' @param ... Column specification objects created by `lcol_*()`.
#' @param .default Deprecated.
#'
#' @export
#' @examples
#' lcols(
#'   id = lcol_int("id"),
#'   name = lcol_chr("name"),
#'   aliases = lcol_lst_of("aliases", character())
#' )
#'
#' # To create multiple columns of the same type use the bang-bang-bang (!!!)
#' # operator together with `purrr::map()`
#' int_cols <- purrr::set_names(c("id", "age"))
#' chr_cols <- purrr::set_names(c("name", "title"))
#'
#' lcols(
#'   !!!purrr::map(int_cols, lcol_int),
#'   !!!purrr::map(chr_cols, lcol_chr)
#' )
lcols <- function(..., .default = zap()) {
  lifecycle::deprecate_warn("0.2.0", "lcols()", "tspec_df()")
  if (!is_zap(.default)) {
    lifecycle::deprecate_stop("0.2.0", "lcols(.default)")
  }

  tspec_df(...)
}

#' Create column specificcation
#'
#' `lcols()` includes all fields in the input data, skipping the column types as the default.
#'
#' @param path A character vector or list that is converted to an extractor function (similar to the `.f` argument in  `purrr::map()`).
#' @param .default Value to use if target is empty or absent. If `zap()` (the default) an error is thrown if target is empty or absent.
#' @param .parser A transformation applied to each element of the list before coercing to `.ptype`. This is usually needed for `lcol_dat()` and `lcol_dtt()`.
#'
#' @param ... Column specification passed on to `lcols()`.
#' @param .ptype The `.ptype` for `vctrs::list_of()`.
#' @param ptype The prototype of the vector.
#'
#' @export
lcol_lgl <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_lgl()", "tib_lgl()")
  tib_lgl(path, required = is_zap(.default), default = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_int <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_int()", "tib_int()")
  tib_int(path, required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_dbl <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_dbl()", "tib_dbl()")
  tib_dbl(path, required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_chr <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_chr()", "tib_chr()")
  tib_chr(path, required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_dat <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_dat()", "tib_scalar()")
  tib_scalar(path, ptype = new_date(), required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_dtt <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_dtt()", "tib_scalar()")
  tib_scalar(path, ptype = new_datetime(tzone = "UTC"), required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_vec <- function(path, ptype, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_vec()", "tib_scalar()")
  tib_scalar(path, ptype = ptype, required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_guess <- function(path, .default = NULL) {
  lifecycle::deprecate_stop("0.2.0", "lcol_guess()")
}

#' @export
#' @rdname lcol_lgl
lcol_skip <- function(path) {
  lifecycle::deprecate_stop("0.2.0", "lcol_skip()")
}

#' @export
#' @rdname lcol_lgl
lcol_lst <- function(path, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_lst()", "tib_variant()")
  tib_variant(path, required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_lst_of <- function(path, .ptype, .default = zap(), .parser = NULL) {
  lifecycle::deprecate_warn("0.2.0", "lcol_lst_of()", "tib_vector()")
  tib_vector(path, .ptype, required = is_zap(.default), fill = if (!is_zap(.default)) .default, transform = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_df_lst <- function(path, ..., .default = zap()) {
  lifecycle::deprecate_warn("0.2.0", "lcol_df_lst()", "tib_df()")
  tib_df(
    path,
    .required = is_zap(.default),
    ...
  )
}

#' @export
#' @rdname lcol_lgl
lcol_df <- function(path, ..., .default = zap()) {
  lifecycle::deprecate_warn("0.2.0", "lcol_df()", "tib_row()")
  tib_row(
    path,
    .required = is_zap(.default),
    ...
  )
}
