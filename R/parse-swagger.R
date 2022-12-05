schema_to_tspec <- function(schema, swagger_spec) {
  schema <- swagger_get_schema(schema, swagger_spec)

  type <- get_swagger_type(schema)
  if (type == "object") {
    fields <- purrr::imap(schema$properties, ~ parse_schema_memoised(.x, .y, swagger_spec))
    fields <- apply_required(fields, schema$required)

    tspec_row(!!!fields)
  } else if (type == "array") {
    schema <- swagger_get_schema(schema$items, swagger_spec)

    fields <- purrr::imap(schema$properties, ~ parse_schema_memoised(.x, .y, swagger_spec))
    fields <- apply_required(fields, schema$required)

    tspec_df(!!!fields)
  }
}

apply_required <- function(fields, required) {
  for (field_name in required) {
    fields[[field_name]]$required <- TRUE
  }

  fields
}

swagger_get_schema <- function(schema, swagger_spec) {
  ref <- schema$`$ref`
  if (!is.null(ref)) {
    ref_parts <- strsplit(ref, "/")[[1]]
    if (ref_parts[[1]] != "#") {
      cli_abort("{.field ref} does not start with {.value #}", .internal = TRUE)
    }
    # TODO better error message
    schema <- purrr::chuck(swagger_spec, !!!ref_parts[-1])
  }

  if (is.null(schema)) {
    cli_abort("No schema found for reference {.value {ref}}")
  }

  # TODO check schema?
  schema
}

get_swagger_type <- function(schema) {
  type <- schema$type
  if (is_null(type)) {
    if (!is_null(schema$properties)) {
      type <- "object"
    } else if (!is_null(schema$items)) {
      type <- "array"
    }
  }

  check_string(type)
  type
}

parse_schema <- function(schema, name, swagger_spec) {
  schema <- swagger_get_schema(schema, swagger_spec)

  type <- get_swagger_type(schema)

  # TODO description, example
  # TODO format?!

  if (is_empty(type)) {
  } else if (type == "object") {
    fields <- purrr::imap(schema$properties, ~ parse_schema_memoised(.x, .y, swagger_spec))
    fields <- apply_required(fields, schema$required)
    tib_row(name, !!!fields, .required = FALSE)

    # TODO additionalProperties?
  } else if (type == "string") {
    # details$default <- schema$default %||% NA_character_
    # if (!is.null(schema$enum)) {
    #   out$type <- "enum"
    #   details$enum <- schema$enum %||% NA_character_
    # } else {
    #   details$pattern <- schema$pattern %||% NA_character_
    # }

    tib_chr(name, required = FALSE)
  } else if (type == "array") {
    # might need to resolve ref
    # need to check type...
    inner_tib <- parse_schema_memoised(schema$items, name, swagger_spec)
    if (is_empty(inner_tib$type)) {
      browser()
    }
    if (inner_tib$type == "scalar") {
      tib_vector(name, inner_tib$ptype, required = FALSE)
    } else if (inner_tib$type == "row") {
      tib_df(name, !!!inner_tib$fields, .required = FALSE)
    } else {
      browser()
    }

    # details$minItems <- schema$minItems %||% NA_integer_
    # details$maxItems <- schema$maxItems %||% NA_integer_
    # details$items <- schema$items %||% NA_integer_
  } else if (type == "integer") {
    # details$minimum <- schema$minimum %||% NA_integer_
    # details$maximum <- schema$maximum %||% NA_integer_
    # details$default <- schema$default %||% NA_integer_

    tib_int(name, required = FALSE)
  } else if (type == "boolean") {
    tib_lgl(name, required = FALSE)
  } else if (type == "number") {
    tib_dbl(name, required = FALSE)
  } else {
    browser()
  }

  # TODO `anyOf`
}

parse_schema_memoised <- memoise::memoise(parse_schema)

ops <- c("get", "put", "post", "delete", "options", "head", "patch", "trace")

parse_path_object <- function(path_object, swagger_spec) {
  operations <- path_object[intersect(names(path_object), ops)]
  purrr::map(operations, ~ parse_operation_object(.x, swagger_spec))
}

parse_operation_object <- function(operation_object, swagger_spec) {
  responses <- operation_object$responses

  purrr::map(
    responses,
    function(response) {
      purrr::map(response$content, ~ parse_media_type_object(.x, swagger_spec))
    }
  )
}

parse_media_type_object <- function(media_type_object, swagger_spec) {
  schema_to_tspec(media_type_object$schema, swagger_spec)
}
