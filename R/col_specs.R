lcollector <- function(path, type, ptype, .default, .parser = NULL,
                       .parser_expr = substitute(.parser, parent.frame(1)),
                       ...) {
  check_default(.default, ptype, path)

  if (type %in% c("df", "df_lst", "lst", "lst_of")) {
    type2 <- type
  } else {
    type2 <- "vector"
  }

  new_lcollector(
    path,
    type,
    type2 = type2,
    .default = .default,
    .parser = .parser,
    .parser_expr = .parser_expr,
    ptype = ptype,
    ...
  )
}


check_default <- function(default, ptype, path) {
  if (is_zap(default)) {
    return()
  }

  if (is_null(ptype)) {
    return()
  }

  if (!vec_is_list(ptype) && vec_size(default) != 1) {
    msg <- c(
      paste0("error in specification for path ", deparse(path)),
      x = paste0("`default` must have size 1, is ", vec_size(default))
    )

    abort(msg, class = "vctrs_error_incompatible_size")
  }

  tryCatch(
    vec_ptype2(ptype, default),
    vctrs_error_incompatible_type = function(err) {
      msg <- c(
        paste0("error in specification for path ", deparse(path)),
        i = "`default` and `ptype` are incompatible.",
        x = err$message
      )
      abort(msg, class = "vctrs_error_incompatible_type", parent = err)
    }
  )
}


new_lcollector <- function(path, type, type2, .default, .parser, ...) {
  structure(
    list(
      # path = as.list(path),
      path = path,
      .default = .default,
      .parser = .parser,
      ...
    ),
    class = c(
      paste0("lcollector_", type),
      paste0("lcollector_", type2),
      "lcollector"
    )
  )
}


is_lcollector <- function(x) {
  inherits(x, "lcollector")
}

is_skip_col <- function(x) {
  class(x)[[1]] == "lcollector_skip"
  # inherits(x, "lcollector_skip")
}

is_guess_col <- function(x) {
  class(x)[[1]] == "lcollector_guess"
  # inherits(x, "lcollector_skip")
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
  lcollector(path, "lgl", ptype = logical(), .default = .default, .parser = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_int <- function(path, .default = zap(), .parser = NULL) {
  lcollector(path, "int", ptype = integer(), .default = .default, .parser = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_dbl <- function(path, .default = zap(), .parser = NULL) {
  lcollector(path, "dbl", ptype = double(), .default = .default, .parser = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_chr <- function(path, .default = zap(), .parser = NULL) {
  lcollector(path, "chr", ptype = character(), .default = .default, .parser = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_dat <- function(path, .default = zap(), .parser = NULL) {
  lcollector(
    path,
    "dat",
    ptype = new_date(),
    .default = .default,
    .parser = .parser
  )
}

#' @export
#' @rdname lcol_lgl
lcol_dtt <- function(path, .default = zap(), .parser = NULL) {
  lcollector(
    path,
    "dtt",
    ptype = new_datetime(tzone = "UTC"),
    .default = .default,
    .parser = .parser
  )
}

#' @export
#' @rdname lcol_lgl
lcol_vec <- function(path, ptype, .default = zap(), .parser = NULL) {
  lcollector(path, "vec", ptype = ptype, .default = .default, .parser = .parser)
}

#' @export
#' @rdname lcol_lgl
lcol_guess <- function(path, .default = NULL) {
  lcollector(
    path,
    "guess",
    ptype = NULL,
    .default = .default,
    .parser = NULL,
    .parser_expr = NULL
  )
}

#' @export
#' @rdname lcol_lgl
lcol_skip <- function(path) {
  if (!(is_scalar_character(path) || is_zap(path))) {
    abort("path must be a scalar character for `lcol_skip()`")
  }

  lcollector(path, type = "skip", ptype = NULL, .default = zap(), .parser_expr = NULL)
}

#' @export
#' @rdname lcol_lgl
lcol_lst <- function(path, .default = zap(), .parser = NULL) {
  lcollector(
    path,
    "lst",
    ptype = list(),
    .default = .default,
    .parser = .parser
  )
}

#' @export
#' @rdname lcol_lgl
lcol_lst_of <- function(path, .ptype, .default = zap(), .parser = NULL) {
  lcollector(
    path, "lst_of",
    ptype = list_of(.ptype = .ptype),
    .default = .default,
    .parser = .parser,
    .ptype = .ptype
  )
}

#' @export
#' @rdname lcol_lgl
lcol_df_lst <- function(path, ..., .default = zap()) {
  lcollector(
    path,
    "df_lst",
    ptype = NULL,
    .default = .default,
    .parser = lcols(...)
  )
}

#' @export
#' @rdname lcol_lgl
lcol_df <- function(path, ..., .default = zap()) {
  lcollector(
    path,
    "df",
    ptype = NULL,
    .parser = lcols(...),
    .default = .default
  )
}
