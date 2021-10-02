#' @export
print.lcollector <- function(x, ...) {
  cat(format(x, ...))
}


#' @export
print.lcol_spec <- function(x, width = NULL, ...) {
  cat(format.lcol_spec(x, width = width, ...))

  invisible(x)
}


pad <- function(x, n) {
  whitespaces <- paste0(rep(" ", n), collapse = "")
  x <- gsub("\n", paste0("\n", whitespaces), x)
  paste0(whitespaces, x)
}


name_exprs <- function(exprs, names, show_name) {
  # nocov start
  if (length(names) == 0 || length(exprs) == 0) {
    abort("something went wrong")
  }
  # nocov end

  non_syntactic <- !is_syntactic(names)
  names[non_syntactic] <- paste0("`", gsub("`", "\\\\`", names[non_syntactic]), "`")

  ifelse(show_name, paste0(names, " = ", exprs), exprs)
}


format_subtype <- function(f_name, path, cols, default, width, ..., npad = 0) {
  if (!is_skip_col(default)) {
    default <- format_default(default)
  } else {
    default <- NULL
  }

  if (!is.null(path)) {
    path <- deparse(path)
  }

  cols_args <- purrr::map2(
    cols,
    # 3 -> " = "
    # 1 -> trailing comma
    nchar(names(cols)) + 3 + 1,
    function(col, nchar_indent) {
      format(
        col,
        nchar_indent = nchar_indent,
        width = width
      )
    }
  )

  inner <- collapse_with_pad(
    c(path, cols_args, default),
    multi_line = TRUE,
    width = width
  )

  paste0(
    f_name, "(",
    inner,
    ")"
  )
}


#' @export
format.lcollector_df <- function(x, ..., width = NULL, npad = 0) {
  format_subtype(
    "lcol_df",
    path = x$path,
    cols = x$.parser$cols,
    default = x$.default,
    width = width,
    npad = npad
  )
}

#' @export
format.lcollector_df_lst <- function(x, ..., width = NULL, npad = 0) {
  format_subtype(
    "lcol_df_lst",
    path = x$path,
    cols = x$.parser$cols,
    default = x$.default,
    width = width,
    npad = npad
  )
}


has_colour <- function() {
  crayon::has_color() ||
    identical(Sys.getenv("TESTTHAT"), "true")
}


# colourise_lcol <- function(x) {
#   UseMethod("colourise_lcol")
# }
#
# colourise_lcol.logical <- function(x) {
#   crayon::yellow()
# }
#
# colourise_lcol.integer <- function(x) {
#   crayon::green()
# }
#
# colourise_lcol.double <- function(x) {
#   crayon::green()
# }
#
# colourise_lcol.character <- function(x) {
#   crayon::red()
# }
#
# colourise_lcol.factor <- function(x) {
#   crayon::red()
# }
#
# colourise_lcol.Date <- function(x) {
#   crayon::blue()
# }
#
# colourise_lcol.POSIXct <- function(x) {
#   crayon::blue()
# }
#
# colourise_lcol.list <- function(x) {
#   crayon::yellow()
# }
#
# colourise_lcol.vctrs_list_of <- function(x) {
#   crayon::yellow()
# }
#
# colourise_lcol.vctrs_list_of <- function(x) {
#   crayon::cyan()
# }
#
# colourise_lcol.vctrs_list_of <- function(x) {
#   crayon::cyan()
# }


colourise_lcol <- function(f_name) {
  if (has_colour()) {
    type <- sub(x = f_name, pattern = "^lcol_", replacement = "")

    f_name <- switch(
      type,
      "lgl" = crayon::yellow,
      "int" = crayon::green,
      "dbl" = crayon::green,
      "chr" = crayon::red,
      "fct" = crayon::red,
      "dat" = crayon::blue,
      "dtt" = crayon::blue,
      "lst" = crayon::yellow,
      "lst_of" = crayon::yellow,
      "guess" = crayon::cyan,
      "skip" = crayon::cyan,
      "df" = crayon::magenta,
      "df_lst" = crayon::magenta,
      "lst" = crayon::magenta,
      "vec" = crayon::black
    )(f_name)
  }

  f_name
}


#' @export
format.lcollector_vec <- function(x, ...) {
  format.lcollector(x, ptype = deparse(x$ptype), ...)
}


#' @export
format.lcollector <- function(x, ...,
                              parser = x[[".parser_expr"]],
                              npad = 0,
                              multi_line = FALSE,
                              nchar_indent = 0,
                              width = NULL) {
  f_name <- sub("^lcollector_", "lcol_", class(x)[1])

  if (!is.null(parser)) {
    parser <- c(.parser = rlang::quo_name(parser))
  } else {
    parser <- c(.parser = NULL)
  }

  if (is_zap(x$path)) {
    path <- "zap()"
  } else {
    path <- deparse(x$path)
  }

  parts <- c(
    path,
    ...,
    parser,
    format_default(x$.default)
  )

  nchar_prefix <- nchar_indent + nchar(f_name) + 2

  parts <- collapse_with_pad(
    parts,
    multi_line = multi_line,
    nchar_prefix = nchar_prefix,
    width = width
  )

  paste0(colourise_lcol(f_name), "(", parts, ")")
}

collapse_with_pad <- function(x, multi_line, nchar_prefix = 0, width) {
  x_nms <- names2(x)
  x <- name_exprs(x, x_nms, x_nms != "")

  x_single_line <- paste0(x, collapse = ", ")
  x_multi_line <- paste0("\n", paste0(pad(x, 2), collapse = ",\n"), "\n")
  line_length <- nchar(x_single_line) + nchar_prefix

  if (multi_line ||
    length(x) > 2 ||
    line_length > tibblify_width(width)) {
    x_multi_line
  } else {
    x_single_line
  }
}

tibblify_width <- function(width = NULL) {
  width %||% getOption("width")
}


#' @export
format.lcollector_lst_of <- function(x, ...) {
  format.lcollector(x, .ptype = deparse(x$.ptype))
}

format_default <- function(default) {
  if (is_zap(default)) {
    default_chr <- character()
  } else if (is_lcollector(default)) {
    default_chr <- format(default)
  } else {
    default_chr <- deparse(default)
  }

  c(.default = default_chr)
}

#' @export
format.lcol_spec <- function(x, width = NULL, ...) {
  format_subtype(
    "lcols",
    path = NULL,
    cols = x$cols,
    default = x$.default,
    width = width
  )
}


is_syntactic <- function(x) make.names(x) == x
