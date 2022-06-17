
# collectors --------------------------------------------------------------

#' @export
print.spec_tib <- function(x, width = NULL, ...) {
  cat(format(x, width = width, ...))

  invisible(x)
}

#' @export
format.spec_df <- function(x, width = NULL, ...) {
  format_fields(
    "spec_df",
    fields = x$fields,
    width = width,
    args = list(
      .names_to = if (!is.null(x$names_col)) deparse(x$names_col)
    )
  )
}

#' @export
format.spec_row <- function(x, width = NULL, ...) {
  format_fields(
    "spec_row",
    fields = x$fields,
    width = width
  )
}

#' @export
format.spec_object <- function(x, width = NULL, ...) {
  format_fields(
    "spec_object",
    fields = x$fields,
    width = width
  )
}

format_fields <- function(f_name, fields, width, args = NULL) {
  fields_formatted <- purrr::map2(
    fields,
    nchar(paste0(names(fields), " = ", ",")),
    function(col, nchar_indent) {
      format(
        col,
        nchar_indent = nchar_indent,
        width = width
      )
    }
  )

  args <- purrr::compact(args)
  if (is_empty(args)) {
    parts <- fields_formatted
  } else {
    parts <- c(args, fields_formatted)
  }

  if (is_empty(parts)) {
    inner <- ""
  } else {
    inner <- collapse_with_pad(
      parts,
      multi_line = TRUE,
      width = width
    )
  }

  paste0(
    f_name, "(",
    inner,
    ")"
  )
}


# format simple columns ---------------------------------------------------

#' @export
print.tib_collector <- function(x, ...) {
  cat(format(x, ...))
}

#' @export
format.tib_vector <- function(x, ...) {
  format.tib_collector(x, ptype = deparse(x$ptype), ...)
}

#' @export
format.tib_scalar <- function(x, ...,
                              multi_line = FALSE, nchar_indent = 0, width = NULL) {
  parts <- list(
    deparse(x$key),
    ptype = if (class(x)[1] == "tib_scalar" || class(x)[1] == "tib_vector") format_ptype(x$ptype),
    required = if (!x$required) FALSE,
    default = format_default(x$default_value, x$ptype),
    transform = x$transform
  )
  parts <- purrr::discard(parts, is.null)

  f_name <- get_f_name(x)
  nchar_prefix <- nchar_indent + nchar(f_name) + 2
  parts <- collapse_with_pad(
    parts,
    multi_line = multi_line,
    nchar_prefix = nchar_prefix,
    width = width
  )

  paste0(f_name_col(x), "(", parts, ")")
}

#' @export
format.tib_list <- format.tib_scalar
#' @export
format.tib_vector <- format.tib_scalar
#' @export
format.tib_unspecified <- format.tib_scalar


# format nested columns ---------------------------------------------------

#' @export
format.tib_row <- function(x, ..., width = NULL) {
  format_fields(
    "tib_row",
    fields = x$fields,
    width = width,
    args = list(
      deparse(x$key),
      `.required` = if (!x$required) FALSE
    )
  )
}

#' @export
format.tib_df <- function(x, ..., width = NULL) {
  format_fields(
    "tib_df",
    fields = x$fields,
    width = width,
    args = list(
      deparse(x$key),
      `.required` = if (!x$required) FALSE,
      .names_to = if (!is.null(x$names_col)) paste0('"', x$names_col, '"')
    )
  )
}


# colours -----------------------------------------------------------------

f_name_col <- function(x) {
  if (!has_colour()) {
    return(get_f_name(x))
  }

  colour_tib(x)(get_f_name(x))
}

has_colour <- function() {
  cli::num_ansi_colors() > 1 ||
    identical(Sys.getenv("TESTTHAT"), "true")
}

colour_tib <- function(x) {
  UseMethod("colour_tib")
}

#' @export
colour_tib.tib_scalar_logical <- function(x) {cli::col_yellow}
#' @export
colour_tib.tib_scalar_integer <- function(x) {cli::col_green}
#' @export
colour_tib.tib_scalar_double <- function(x) {cli::col_green}
#' @export
colour_tib.tib_scalar_character <- function(x) {cli::col_red}

#' @export
colour_tib.tib_vector_logical <- function(x) {cli::col_yellow}
#' @export
colour_tib.tib_vector_integer <- function(x) {cli::col_green}
#' @export
colour_tib.tib_vector_double <- function(x) {cli::col_green}
#' @export
colour_tib.tib_vector_character <- function(x) {cli::col_red}

#' @export
colour_tib.tib_row <- function(x) {cli::col_magenta}
#' @export
colour_tib.tib_df <- function(x) {cli::col_magenta}

#' @export
colour_tib.default <- function(x) {cli::col_black}


# get_f_name --------------------------------------------------------------

get_f_name <- function(x) {
  UseMethod("get_f_name")
}

#' @export
get_f_name.default <- function(x) {class(x)[[1]]}

#' @export
get_f_name.tib_unspecified <- function(x) {"tib_unspecified"}

#' @export
get_f_name.tib_scalar_logical <- function(x) {"tib_lgl"}
#' @export
get_f_name.tib_scalar_integer <- function(x) {"tib_int"}
#' @export
get_f_name.tib_scalar_double <- function(x) {"tib_dbl"}
#' @export
get_f_name.tib_scalar_character <- function(x) {"tib_chr"}
#' @export
get_f_name.tib_scalar<- function(x) {"tib_scalar"}

#' @export
get_f_name.tib_vector_logical <- function(x) {"tib_lgl_vec"}
#' @export
get_f_name.tib_vector_integer <- function(x) {"tib_int_vec"}
#' @export
get_f_name.tib_vector_double <- function(x) {"tib_dbl_vec"}
#' @export
get_f_name.tib_vector_character <- function(x) {"tib_chr_vec"}
#' @export
get_f_name.tib_vector<- function(x) {"tib_vector"}

#' @export
get_f_name.tib_list <- function(x) {"tib_list"}


# format ptype ------------------------------------------------------------

format_ptype <- function(x) {
  UseMethod("format_ptype")
}

#' @export
format_ptype.default <- function(x) {deparse(x)}

#' @export
format_ptype.difftime <- function(x) {"vctrs::new_duration()"}
#' @export
format_ptype.Date <- function(x) {"vctrs::new_date()"}
#' @export
format_ptype.POSIXct <- function(x) {
  tzone <- attr(x, "tzone")

  paste0(
    "vctrs::new_datetime(",
    if (!is_null(tzone)) paste0("tzone = ", deparse(tzone)),
    ")"
  )
}


# helper functions --------------------------------------------------------

format_default <- function(default, ptype) {
  if (vec_is_empty(default)) return(NULL)
  canonical_default <- vec_init(ptype)
  if (vec_equal(default, canonical_default, na_equal = TRUE)) return(NULL)

  deparse(default)
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

is_syntactic <- function(x) make.names(x) == x


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
