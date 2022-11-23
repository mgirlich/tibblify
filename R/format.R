
# tibblify results --------------------------------------------------------

#' @export
print.tibblify_object <- function(x, ...) {
  attributes(x) <- list(names = names(x))
  print(x)
}

# collectors --------------------------------------------------------------

#' Printing tibblify specifications
#'
#' @param x Spec to format or print
#' @param width Width of text output to generate.
#' @param ... These dots are for future extensions and must be empty.
#' @param names Should names be printed even if they can be deduced from the
#'   spec?
#'
#' @return `x` is returned invisibly.
#' @name formatting
#' @export
#'
#' @examples
#' spec <- tspec_df(
#'   a = tib_int("a"),
#'   new_name = tib_chr("b"),
#'   row = tib_row(
#'     "row",
#'     x = tib_int("x")
#'   )
#' )
#' print(spec, names = FALSE)
#' print(spec, names = TRUE)
print.tspec <- function(x, width = NULL, ..., names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)
  cat(format(x, width = width, ..., names = names))

  invisible(x)
}

#' @rdname formatting
#' @export
format.tspec_df <- function(x, width = NULL, ..., names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    "tspec_df",
    fields = x$fields,
    width = width,
    args = list(
      .names_to = if (!is.null(x$names_col)) deparse(x$names_col),
      vector_allows_empty_list = if (x$vector_allows_empty_list) x$vector_allows_empty_list,
      .input_form = if (x$input_form != "rowmajor") double_tick(x$input_form)
    ),
    force_names = names
  )
}

#' @export
format.tspec_row <- function(x, width = NULL, ..., names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    "tspec_row",
    fields = x$fields,
    width = width,
    args = list(
      vector_allows_empty_list = if (x$vector_allows_empty_list) x$vector_allows_empty_list,
      .input_form = if (x$input_form != "rowmajor") double_tick(x$input_form)
    ),
    force_names = names
  )
}

#' @export
format.tspec_recursive <- function(x, width = NULL, ..., names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    "tspec_recursive",
    fields = x$fields,
    width = width,
    args = list(
      .children = double_tick(x$child),
      .children_to = if (x$child != x$children_to) double_tick(x$children_to),
      vector_allows_empty_list = if (x$vector_allows_empty_list) x$vector_allows_empty_list,
      .input_form = if (x$input_form != "rowmajor") double_tick(x$input_form)
    ),
    force_names = names
  )
}

#' @export
format.tspec_object <- function(x, width = NULL, ..., names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    "tspec_object",
    fields = x$fields,
    width = width,
    args = list(
      vector_allows_empty_list = if (x$vector_allows_empty_list) x$vector_allows_empty_list,
      .input_form = if (x$input_form != "rowmajor") double_tick(x$input_form)
    ),
    force_names = names
  )
}

format_fields <- function(f_name, fields, width, args = NULL, force_names) {
  if (force_names) {
    canonical_name <- FALSE
  } else {
    canonical_name <- purrr::map2_lgl(fields, names2(fields), is_tib_name_canonical)
    names2(fields)[canonical_name] <- ""
  }

  fields_formatted <- purrr::map2(
    fields,
    ifelse(canonical_name, 0, nchar(paste0(names(fields), " = ", ","))),
    function(col, nchar_indent) {
      format(
        col,
        nchar_indent = nchar_indent,
        width = width
      )
    }
  )

  args <- list_drop_null(args)
  if (is_empty(args)) {
    parts <- fields_formatted
  } else {
    parts <- c(args, fields_formatted)
  }

  if (is_empty(parts)) {
    return(paste0(f_name, "()"))
  }

  inner <- collapse_with_pad(
    parts,
    multi_line = TRUE,
    width = width
  )

  paste0(
    f_name, "(",
    inner,
    ")"
  )
}

is_tib_name_canonical <- function(field, name) {
  key <- field$key
  if (vec_size(key) > 1 || !is.character(key)) {
    return(FALSE)
  }

  key == name
}


# format simple columns ---------------------------------------------------

#' @export
print.tib_collector <- function(x, width = NULL, ..., names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  cat(format(x, width = width, ..., names = names))
  invisible(x)
}

#' @export
format.tib_scalar <- function(x,
                              ...,
                              fill = NULL,
                              ptype_inner = NULL,
                              transform = NULL,
                              multi_line = FALSE,
                              nchar_indent = 0,
                              width = NULL,
                              names = FALSE) {
  parts <- list(
    deparse(x$key),
    ptype = format_ptype_arg(x),
    required = if (!x$required) FALSE,
    fill = format_fill_arg(x, fill),
    ptype_inner = format_ptype_inner(x, ptype_inner),
    transform = if (!is_zap(transform)) x$transform,
    ...
  )
  parts <- list_drop_null(parts)

  f_name <- format_tib_f(x)
  nchar_prefix <- nchar_indent + cli::ansi_nchar(f_name) + 2
  parts <- collapse_with_pad(
    parts,
    multi_line = multi_line,
    nchar_prefix = nchar_prefix,
    width = width
  )

  paste0(f_name, "(", parts, ")")
}

#' @export
format.tib_variant <- function(x, ...,
                              multi_line = FALSE,
                              nchar_indent = 0,
                              width = NULL) {
  format.tib_scalar(
    x = x,
    elt_transform = x$elt_transform,
    multi_line = multi_line,
    nchar_indent = nchar_indent,
    width = width
  )
}
#' @export
format.tib_vector <- function(x, ...,
                              multi_line = FALSE,
                              nchar_indent = 0,
                              width = NULL) {
  format.tib_scalar(
    x = x,
    elt_transform = x$elt_transform,
    input_form = if (!identical(x$input_form, "vector")) {
      double_tick(x$input_form)
    },
    values_to = double_tick(x$values_to),
    names_to = double_tick(x$names_to),
    multi_line = multi_line,
    nchar_indent = nchar_indent,
    width = width
  )
}
#' @export
format.tib_unspecified <- format.tib_scalar


#' @export
format.tib_scalar_chr_date <- function(x, ...,
                                       multi_line = FALSE,
                                       nchar_indent = 0,
                                       width = NULL) {
  format.tib_scalar(
    x = x,
    fill = if (identical(x$fill, NA_character_)) zap(),
    ptype_inner = zap(),
    format = if (x$format != "%Y-%m-%d") double_tick(x$format),
    transform = zap(),
    multi_line = multi_line,
    nchar_indent = nchar_indent,
    width = width
  )
}

#' @export
format.tib_vector_chr_date <- format.tib_scalar_chr_date

# format nested columns ---------------------------------------------------

#' @export
format.tib_row <- function(x, ..., width = NULL, names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    format_tib_f(x),
    fields = x$fields,
    width = width,
    args = list(
      deparse(x$key),
      `.required` = if (!x$required) FALSE
    ),
    force_names = names
  )
}

#' @export
format.tib_df <- function(x, ..., width = NULL, names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    format_tib_f(x),
    fields = x$fields,
    width = width,
    args = list(
      deparse(x$key),
      `.required` = if (!x$required) FALSE,
      .names_to = double_tick(x$names_col)
    ),
    force_names = names
  )
}

#' @export
format.tib_recursive <- function(x, ..., width = NULL, names = NULL) {
  names <- names %||% should_force_names()
  check_bool(names)

  format_fields(
    format_tib_f(x),
    fields = x$fields,
    width = width,
    args = list(
      deparse(x$key),
      `.children` = double_tick(x$child),
      .children_to = if (x$child != x$children_to) double_tick(x$children_to),
      `.required` = if (!x$required) FALSE
    ),
    force_names = names
  )
}


# colours -----------------------------------------------------------------

format_tib_f <- function(x) {
  UseMethod("format_tib_f")
}

#' @export
format_tib_f.tib_unspecified <- function(x) {"tib_unspecified"}

#' @export
format_tib_f.tib_scalar_logical <- function(x) {cli::col_yellow("tib_lgl")}
#' @export
format_tib_f.tib_scalar_integer <- function(x) {cli::col_green("tib_int")}
#' @export
format_tib_f.tib_scalar_numeric <- function(x) {cli::col_green("tib_dbl")}
#' @export
format_tib_f.tib_scalar_character <- function(x) {cli::col_red("tib_chr")}
#' @export
format_tib_f.tib_scalar_date <- function(x) {"tib_date"}
#' @export
format_tib_f.tib_scalar_chr_date <- function(x) {"tib_chr_date"}
#' @export
format_tib_f.tib_scalar<- function(x) {"tib_scalar"}

#' @export
format_tib_f.tib_vector_logical <- function(x) {cli::col_yellow("tib_lgl_vec")}
#' @export
format_tib_f.tib_vector_integer <- function(x) {cli::col_green("tib_int_vec")}
#' @export
format_tib_f.tib_vector_numeric <- function(x) {cli::col_green("tib_dbl_vec")}
#' @export
format_tib_f.tib_vector_character <- function(x) {cli::col_red("tib_chr_vec")}
#' @export
format_tib_f.tib_vector_date <- function(x) {cli::col_red("tib_date_vec")}
#' @export
format_tib_f.tib_vector_chr_date <- function(x) {"tib_chr_date_vec"}
#' @export
format_tib_f.tib_vector <- function(x) {"tib_vector"}

#' @export
format_tib_f.tib_variant <- function(x) {"tib_variant"}

#' @export
format_tib_f.tib_row <- function(x) {cli::col_magenta("tib_row")}
#' @export
format_tib_f.tib_df <- function(x) {cli::col_magenta("tib_df")}
#' @export
format_tib_f.tib_recursive <- function(x) {cli::col_magenta("tib_recursive")}

#' @export
format_tib_f.default <- function(x) {class(x)[[1]]} # nocov


# format ptype ------------------------------------------------------------

format_ptype_inner <- function(x, ptype_inner) {
  if (is_zap(ptype_inner)) return(NULL)
  if (is_null(x$ptype_inner)) return(NULL)
  if (!identical(x$ptype, x$ptype_inner)) format_ptype(x$ptype_inner)
}

format_ptype_arg <- function(x) {
  if (!class(x)[1] %in% c("tib_scalar", "tib_vector")) {
    return(NULL)
  }

  format_ptype(x$ptype)
}

format_ptype <- function(x) {
  UseMethod("format_ptype")
}

#' @export
format_ptype.default <- function(x) {deparse(x)}

#' @export
format_ptype.difftime <- function(x) {
  if (!identical(class(x), "difftime")) return(deparse(x))

  "vctrs::new_duration()"
}
#' @export
format_ptype.Date <- function(x) {
  if (!vec_is(x, vctrs::new_date())) return(deparse(x))

  "vctrs::new_date()"
}
#' @export
format_ptype.POSIXct <- function(x) {
  tzone <- attr(x, "tzone")
  tzone_str <- if (!is_null(tzone)) paste0("tzone = ", deparse(tzone))

  paste0("vctrs::new_datetime(", tzone_str,")")
}


# format fill -------------------------------------------------------------

format_fill_arg <- function(x, fill) {
  if (is_zap(fill)) return(NULL)

  if (is_null(x$fill)) return(NULL)

  if (is_tib_variant(x) || is_tib_unspecified(x)) {
    return(deparse(x$fill))
  }

  if (is_tib_scalar(x)) {
    canonical_default <- vec_init(x$ptype_inner)
  } else if (is_tib_vector(x)) {
    canonical_default <- vec_init(x$ptype)
  } else {
    cli::cli_abort("{.arg x} has unexpected type {.cls class(x)}.", .internal = TRUE) # nocov
  }

  canonical <- vec_size(x$fill) == 1 && vec_equal(x$fill, canonical_default, na_equal = TRUE)
  if (canonical) return(NULL)

  format_fill(x$fill)
}

format_fill <- function(x) {
  UseMethod("format_fill")
}

#' @export
format_fill.default <- function(x) {
  deparse(x)
}

#' @export
format_fill.Date <- function(x) {
  paste0("as.Date(", double_tick(format(x, format = "%Y-%m-%d")), ")")
}

# helper functions --------------------------------------------------------

double_tick <- function(x) {
  if (is_null(x)) {
    return(NULL)
  }

  paste0('"', x, '"')
}

collapse_with_pad <- function(x, multi_line, nchar_prefix = 0, width) {
  x_nms <- names2(x)
  x <- name_exprs(x, x_nms, x_nms != "")

  x_single_line <- paste0(x, collapse = ", ")
  x_multi_line <- paste0("\n", paste0(pad(x, 2), ",", collapse = "\n"), "\n")
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

is_syntactic <- function(x) make.names(x) == x


pad <- function(x, n) {
  whitespaces <- paste0(rep(" ", n), collapse = "")
  x <- gsub("\n", paste0("\n", whitespaces), x)
  paste0(whitespaces, x)
}


name_exprs <- function(exprs, names, show_name) {
  # nocov start
  if (length(names) == 0 || length(exprs) == 0) {
    cli::cli_abort("Empty names or empty exprs", .internal = TRUE)
  }
  # nocov end

  non_syntactic <- !is_syntactic(names)
  names[non_syntactic] <- paste0("`", gsub("`", "\\\\`", names[non_syntactic]), "`")

  ifelse(show_name, paste0(names, " = ", exprs), exprs)
}

should_force_names <- function() {
  getOption("tibblify.print_names", default = FALSE)
}
