#' Unpack a tibblify specification
#'
#' @param spec A tibblify specification.
#' @param ... These dots are for future extensions and must be empty.
#' @param fields A string of the fields to unpack.
#' @param recurse Should unpack recursively?
#' @param names_sep If `NULL`, the default, the inner names of fields are used.
#'   If a string, the outer and inner names are pasted together, separated by
#'   `names_sep`.
#' @param names_repair Used to check that output data frame has valid names.
#'   Must be one of the following options:
#'
#' * `"unique"` or `"unique_quiet"`: (the default) make sure names are unique and not empty,
#'
#' * `"universal" or `"unique_quiet"`: make the names unique and syntactic
#'
#' * `"check_unique"`: no name repair, but check they are unique,
#'
#' * a function: apply custom name repair.
#'
#' See [vctrs::vec_as_names()] for more information.
#' @param names_clean A function to clean names after repairing. For example
#'   use [camel_case_to_snake_case()].
#'
#' @return A tibblify spec.
#' @export
#'
#' @examples
#' spec <- tspec_df(
#'   tib_lgl("a"),
#'   tib_row("x", tib_int("b"), tib_chr("c")),
#'   tib_row("y", tib_row("z", tib_chr("d")))
#' )
#'
#' unpack_tspec(spec)
#' # only unpack `x`
#' unpack_tspec(spec, fields = "x")
#' # do not unpack the fields in `y`
#' unpack_tspec(spec, recurse = FALSE)
unpack_tspec <- function(spec,
                         ...,
                         fields = NULL,
                         recurse = TRUE,
                         names_sep = NULL,
                         names_repair = c("unique", "universal", "check_unique", "unique_quiet", "universal_quiet"),
                         names_clean = NULL) {
  rlang::check_dots_empty()
  check_character(fields, allow_null = TRUE)
  check_bool(recurse)
  check_string(names_sep, allow_null = TRUE)
  names_repair <- arg_match(names_repair)
  check_function(names_clean, allow_null = TRUE)

  fields_to_unpack <- check_unpack_cols(fields, spec)
  error_call <- current_call()

  spec$fields <- with_indexed_errors(
    purrr::imap(
      spec$fields,
      function(field, name) {
        if (!name %in% fields_to_unpack) {
          return(set_names(list(field), name))
        }

        unpack_field(
          field,
          recurse = recurse,
          name = name,
          names_sep = names_sep,
          names_repair = names_repair,
          names_clean = names_clean,
          error_call = NULL
        )
      }
    ),
    message = "In field {.field {cnd$name}}."
  )

  spec$fields <- unchop_fields(spec$fields, names_repair, names_clean, error_call)
  spec
}

check_unpack_cols <- function(fields, spec, error_call = caller_env()) {
  known_fields <- names(spec$fields)
  fields <- fields %||% known_fields
  missing_fields <- setdiff(fields, known_fields)
  if (!is_empty(missing_fields)) {
    msg <- c(
      "Can't unpack fields that don't exist.",
      "Field{?s} {.field {missing_fields}} {?doesn/don}'t exist."
    )
    cli_abort(msg)
  }

  fields
}

unpack_field <- function(field_spec,
                         recurse,
                         name,
                         names_sep,
                         names_repair,
                         names_clean,
                         error_call) {
  if (recurse && field_spec$type %in% c("row", "df")) {
    field_spec$fields <- purrr::imap(
      field_spec$fields,
      function(field, name) {
        unpack_field(
          field,
          recurse = recurse,
          name = name,
          names_sep = names_sep,
          names_repair = names_repair,
          names_clean = names_clean,
          error_call = error_call
        )
      }
    )

    field_spec$fields <- unchop_fields(
      field_spec$fields,
      names_repair,
      names_clean,
      error_call
    )
  }

  if (field_spec$type != "row") {
    return(set_names(list(field_spec), name))
  }

  row_fields <- purrr::map(field_spec$fields, function(row_field) {
    row_field$key <- c(field_spec$key, row_field$key)
    row_field
  })

  if (is.null(names_sep)) {
    row_fields
  } else {
    names <- paste0(name, names_sep, names(row_fields))
    set_names(row_fields, names)
  }
}

unchop_fields <- function(fields, names_repair, names_clean, error_call) {
  fields <- vctrs::list_unchop(fields, name_spec = "{inner}")
  nms <- names(fields)
  nms <- vctrs::vec_as_names(nms, repair = names_repair, call = error_call)
  if (!is.null(names_clean)) {
    nms <- names_clean(nms)
  }
  set_names(fields, nms)
}

#' @param names Names to clean
#'
#' @export
#' @rdname unpack_tspec
camel_case_to_snake_case <- function(names) {
  names <- gsub(
    "([A-Z]+)",
    "_\\1",
    names
  )

  tolower(names)
}
