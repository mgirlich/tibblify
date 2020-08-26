#' @export
print.lcollector <- function(x, ...) {
  cat(format(x, ...))
}


#' @export
print.lcol_spec <- function(x, n = Inf, condense = NULL, colour = has_colour(), ...) {
  cat(format.lcol_spec(x, n = n, condense = condense, colour = colour, ...))

  invisible(x)
}


pad <- function(x, n) {
  whitespaces <- paste0(rep(" ", n), collapse = "")
  x <- gsub("\n", paste0("\n", whitespaces), x)
  paste0(whitespaces, x)
}


name_exprs <- function(exprs, names, show_name) {
  if (length(names) == 0 || length(exprs) == 0) {
    return(character())
  }

  non_syntactic <- !is_syntactic(names)
  names[non_syntactic] <- paste0("`", gsub("`", "\\\\`", names[non_syntactic]), "`")

  ifelse(show_name, paste0(names, " = ", exprs), exprs)
}


format_subtype <- function(x, f_name, npad = 0) {
  body_parts <- lapply(x$.parser$cols, format, npad = npad + 2)

  format.lcollector(
    x,
    body_parts,
    parser = NULL,
    npad = npad,
    multi_line = TRUE
  )
}


#' @export
format.lcollector_df <- function(x, ..., npad = 0) {
  format_subtype(x, "lcol_df", npad)
}

#' @export
format.lcollector_df_lst <- function(x, ..., npad = 0) {
  format_subtype(x, "lcol_df_lst", npad)
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
      "df" = ,
      "df_lst" = ,
      "lst" = crayon::magenta,
      "vec" = crayon::black
    )(f_name)
  }

  f_name
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
    format_default(x)
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
  NULL %||% getOption("width")
}


#' @export
format.lcollector_lst_of <- function(x, ...) {
  format.lcollector(x, .ptype = deparse(x$.ptype))
}

format_default <- function(x) {
  c(.default = format(x$.default))
}

#' @export
format.lcol_spec <- function(x, width = NULL, ...) {
  cols <- x$cols

  if (length(cols) == 0) {
    out <- paste0("lcols(", format_default(x$.default), ")")
  } else {
    if (!is_skip_col(x$.default)) {
      default <- format_default(x)
    } else {
      default <- NULL
    }

    cols_args <- purrr::map2(
      cols,
      nchar(names(cols)) + 3,
      function(col, nchar_indent) {
        format(
          col,
          nchar_indent = nchar_indent,
          width = width
        )
      }
    )

    inner <- collapse_with_pad(
      c(cols_args, default),
      multi_line = TRUE,
      width = width
    )

    out <- paste0(
      "lcols(",
      inner,
      ")\n"
    )
  }


  out
}


is_syntactic <- function(x) make.names(x) == x
