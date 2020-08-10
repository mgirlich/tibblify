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


format_subtype <- function(x, f_name, npad = 0, show_auto_names = FALSE) {
  # body_names <- names(x$.parser$cols)
  body_parts <- lapply(x$.parser$cols, format, npad = npad + 2)
  # TODO handle auto name?
  # show_name <- !(attr(x$.parser$cols, "auto_name") %||% rlang::rep_along(x$.parser$cols, TRUE)) | show_auto_names

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
      "dbl" =  crayon::green,
      "chr" = crayon::red,
      "fct" =  crayon::red,
      "dat" =  crayon::blue,
      "dtt" = crayon::blue,
      "lst" =  crayon::yellow,
      "lst_flat" = crayon::yellow,
      "guess" = crayon::cyan,
      "skip" = crayon::cyan,
      "df" = ,
      "df_lst" = ,
      "lst" = crayon::magenta
    )(f_name)
  }

  f_name
}


#' @export
format.lcollector <- function(x, ...,
                              parser = x[[".parser_expr"]],
                              npad = 0,
                              multi_line = FALSE) {
  f_name <- colourise_lcol(sub("^lcollector_", "lcol_", class(x)[1]))

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

  parts <- collapse_with_pad(parts, multi_line = multi_line)

  paste0(f_name, "(", parts, ")")
}

collapse_with_pad <- function(x, multi_line) {
  x_nms <- names2(x)
  x <- name_exprs(x, x_nms, x_nms != "")

  x_single_line <- paste0(x, collapse = ", ")
  x_multi_line <- paste0("\n", paste0(pad(x, 2), collapse = ",\n"), "\n")

  if (multi_line || length(x) > 2 || nchar(x_single_line) > 70) {
    x_multi_line
  } else {
    x_single_line
  }
}


#' @export
format.lcollector_lst_flat <- function(x, ...) {
  format.lcollector(x, .ptype = deparse(x$.ptype))
}

format_default <- function(x) {
  c(.default = format(x$.default))
}

#' @export
format.lcol_spec <- function(x, n = Inf, show_auto_names = FALSE, ...) {
  if (n == 0) {
    return("")
  }

  # truncate to minumum of n or length
  n_cols <- length(x$cols)
  cols <- x$cols[seq_len(min(n_cols, n))]

  cols_args <- c(vapply(cols, format, character(1)))

  if (length(cols) == 0) {
    out <- paste0("lcols(", format_default(x$.default), ")")
  } else {
    show_name <- !(attr(x$cols, "auto_name") %||% rlang::rep_along(cols, TRUE)) | show_auto_names

    if (!is_skip_col(x$.default)) {
      default <- format_default(x)
    } else {
      default <- NULL
    }

    inner <- collapse_with_pad(c(cols_args, default), multi_line = TRUE)

    out <- paste0(
      "lcols(",
      inner,
      ")\n"
    )
  }

  out
}


is_syntactic <- function(x) make.names(x) == x
