unpack_tspec <- function(spec,
                         ...,
                         fields = NULL,
                         recurse = TRUE,
                         names_sep = NULL,
                         names_repair = "check_unique") {
  fields_to_unpack <- check_unpack_cols(fields, spec)

  browser()
  # spec$fields[fields_to_unpack] <-
  purrr::map(
    spec$fields[fields_to_unpack],
    function(field) {
      unpack_fields(
        ,
        names_sep,
        recurse = recurse
      )
    }
  )
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

unpack_fields <- function(fields_spec, names_sep, recurse) {
  fields_out <- list()
  names <- character()

  for (i in seq_along(fields_spec)) {
    field_i <- fields_spec[[i]]
    name_i <- names(fields_spec)[[i]]

    if (recurse && field_i$type %in% c("row", "df")) {
      field_i$fields <- unpack_fields(
        field_i$fields,
        names_sep = names_sep,
        recurse = recurse
      )
    }

    if (field_i$type == "row") {
      row_fields <- purrr::map(field_i$fields, function(row_field) {
        row_field$key <- c(field_i$key, row_field$key)
        row_field
      })
      fields_out <- c(fields_out, unname(row_fields))

      if (is.null(names_sep)) {
        names <- c(names, names(row_fields))
      } else {
        nms <- paste0(name_i, names_sep, names(row_fields))
        names <- c(names, nms)
      }
    } else {
      fields_out <- c(fields_out, list(field_i))
      names <- c(names, name_i)
    }
  }

  set_names(fields_out, names)
}
