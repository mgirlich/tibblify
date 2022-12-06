#' Parse an OpenAPI spec
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Use `parse_openapi_spec()` to parse a [OpenAPI spec](https://swagger.io/specification/)
#' or use `parse_openapi_schema()` to parse a OpenAPI schema.
#'
#' @param file Either a path to a file, a connection, or literal data (a
#'   single string).
#'
#' @return For `parse_openapi_spec()` a data frame with the columns
#'
#'   * `endpoint` `<character>` Name of the endpoint.
#'   * `operation` `<character>` The http operation; one of `"get"`, `"put"`,
#'       `"post"`, `"delete"`, `"options"`, `"head"`, `"patch"`, or `"trace"`.
#'   * `status_code` `<character>` The http status code. May contain wildcards like
#'       `2xx` for all response codes between `200` and `299`.
#'   * `media_type` `<character>` The media type.
#'   * `spec` `<list>` A list of tibblify specifications.
#'
#'   For `parse_openapi_schema()` a tibblify spec.
#' @export
#'
#' @examples
#' file <- '{
#'   "$schema": "http://json-schema.org/draft-04/schema",
#'   "title": "Starship",
#'   "description": "A vehicle.",
#'   "type": "object",
#'   "properties": {
#'     "name": {
#'       "type": "string",
#'       "description": "The name of this vehicle. The common name, such as Sand Crawler."
#'     },
#'     "model": {
#'       "type": "string",
#'       "description": "The model or official name of this vehicle. Such as All Terrain Attack Transport."
#'     },
#'     "url": {
#'       "type": "string",
#'       "format": "uri",
#'       "description": "The hypermedia URL of this resource."
#'     },
#'     "edited": {
#'       "type": "string",
#'       "format": "date-time",
#'       "description": "the ISO 8601 date format of the time that this resource was edited."
#'     }
#'   },
#'   "required": [
#'     "name",
#'     "model",
#'     "edited"
#'   ]
#' }'
#'
#' parse_openapi_schema(file)
parse_openapi_spec <- function(file) {
  openapi_spec <- read_spec(file)
  version <- openapi_spec$openapi %||% openapi_spec$info$version
  if (version < "3") {
    cli_abort("OpenAPI versions before 3 are not supported.")
  }
  # cannot use `openapi_spec` for memoising, as hashing it takes much more time
  # than everything else. To still make sure the result is correct simply forget
  # previous results.
  if (is_installed("memoise")) {
    memoise::forget(parse_schema_memoised)
  }

  out <- purrr::imap(
    openapi_spec$paths,
    ~ {
      parse_path_object(
        path_object = .x,
        openapi_spec = openapi_spec
      )
    }
  )

  vctrs::vec_rbind(!!!out, .names_to = "endpoint")
}

#' @export
#' @rdname parse_openapi_spec
parse_openapi_schema <- function(file) {
  rlang::check_installed("memoise")
  openapi_spec <- read_spec(file)
  out <- parse_schema(openapi_spec, "a", openapi_spec)
  memoise::forget(parse_schema_memoised)

  if (out$type == "row") {
    tspec_row(!!!out$fields)
  } else {
    tspec_df(!!!out$fields)
  }
}

read_spec <- function(file, arg = caller_arg(file), call = caller_env()) {
  rlang::check_installed("yaml")
  if (is_character(file)) {
    check_string(file)

    if (grepl("\n", file)) {
      yaml::yaml.load(file)
    } else {
      yaml::read_yaml(file)
    }
  } else if (inherits(file, "connection")) {
    yaml::read_yaml(file)
  } else {
    stop_input_type(
      file,
      c("a string", "a connection")
    )
  }
}

parse_path_object <- function(path_object, openapi_spec) {
  ops <- c("get", "put", "post", "delete", "options", "head", "patch", "trace")

  operations <- path_object[intersect(names(path_object), ops)]
  out <- purrr::imap(operations, ~ parse_operation_object(.x, openapi_spec))
  vctrs::vec_rbind(!!!out, .names_to = "operation")
}

parse_operation_object <- function(operation_object, openapi_spec) {
  operation_object <- openapi_get_schema(operation_object, openapi_spec)

  out <- purrr::map(operation_object$responses, ~ parse_response_object(.x, openapi_spec))
  vctrs::vec_rbind(!!!out, .names_to = "status_code")
}

parse_response_object <- function(response_object, openapi_spec) {
  response_object <- openapi_get_schema(response_object, openapi_spec)

  out <- purrr::map(response_object$content, ~ parse_media_type_object(.x, openapi_spec))
  vctrs::new_data_frame(
    list(media_type = names(out), spec = unname(out)),
    n = length(out)
  )
}

parse_media_type_object <- function(media_type_object, openapi_spec) {
  schema_to_tspec(media_type_object$schema, openapi_spec)
}

schema_to_tspec <- function(schema, openapi_spec) {
  schema <- openapi_get_schema(schema, openapi_spec)

  if (!is.null(schema$oneOf)) {
    out <- handle_one_of_tspec(schema, openapi_spec)
    return(out)
  }
  if (!is.null(schema$allOf)) {
    out <- handle_all_of_tspec(schema, openapi_spec)
    return(out)
  }

  type <- get_openapi_type(schema)
  if (type == "object") {
    fields <- purrr::imap(schema$properties, ~ parse_schema_memoised(.x, .y, openapi_spec))
    fields <- apply_required(fields, schema$required)

    tspec_row(!!!fields)
  } else if (type == "array") {
    schema <- openapi_get_schema(schema$items, openapi_spec)

    fields <- purrr::imap(schema$properties, ~ parse_schema_memoised(.x, .y, openapi_spec))
    fields <- apply_required(fields, schema$required)

    tspec_df(!!!fields)
  } else {
    # this is a bit of a hack...
    out <- parse_schema(schema, "dummy", openapi_spec)
    out$required <- TRUE

    out
  }
}

apply_required <- function(fields, required) {
  for (field_name in required) {
    fields[[field_name]]$required <- TRUE
  }

  fields
}

openapi_get_schema <- function(schema, openapi_spec) {
  ref <- schema$`$ref`
  # FIXME this is probably quite a hack...
  ref <- ref %||% schema$allOf[[1]]$`$ref`
  if (!is.null(ref)) {
    ref_parts <- strsplit(ref, "/")[[1]]
    if (ref_parts[[1]] != "#") {
      cli_abort("{.field ref} does not start with {.value #}", .internal = TRUE)
    }
    # TODO better error message
    tryCatch({
      schema <- purrr::chuck(openapi_spec, !!!ref_parts[-1])
    }, error = function(cnd) {
      browser()
    }
    )
    schema <- purrr::chuck(openapi_spec, !!!ref_parts[-1])
  }

  if (is.null(schema)) {
    cli_abort("No schema found for reference {.value {ref}}")
  }

  # TODO check schema?
  schema
}

get_openapi_type <- function(schema) {
  type <- schema$type
  if (is_null(type)) {
    if (!is_null(schema$properties)) {
      type <- "object"
    } else if (!is_null(schema$items)) {
      type <- "array"
    }
  }

  check_string(type, allow_null = TRUE)
  type %||% "variant"
}

parse_schema <- function(schema, name, openapi_spec) {
  schema <- openapi_get_schema(schema, openapi_spec)
  if (!is.null(schema$oneOf)) {
    out <- handle_one_of(schema, name, openapi_spec)
    return(out)
  }
  if (!is.null(schema$allOf)) {
    out <- handle_all_of(schema, name, openapi_spec)
    return(out)
  }

  type <- get_openapi_type(schema)

  # TODO description, example
  # TODO format?!

  if (is_empty(type)) {
  } else if (type == "object") {
    fields <- purrr::imap(schema$properties, ~ parse_schema_memoised(.x, .y, openapi_spec))
    fields <- apply_required(fields, schema$required)
    tib_row(name, !!!fields, .required = FALSE)

    # TODO additionalProperties?
  } else if (type == "string") {
    # TODO support for `enum` or `pattern`?
    tib_chr(name, required = FALSE)
  } else if (type == "array") {
    items <- schema$items
    if (is_null(items)) {
      cli::cli_inform("Array has no items")
      field_spec <- tib_variant(name)
      return(field_spec)
    }

    inner_tib <- parse_schema_memoised(schema$items, name, openapi_spec)
    if (inner_tib$type == "scalar") {
      tib_vector(name, inner_tib$ptype, required = FALSE)
    } else if (inner_tib$type == "row") {
      tib_df(name, !!!inner_tib$fields, .required = FALSE)
    } else {
      inner_tib
    }
    # TODO support for `minItems`, `maxItems`?
  } else if (type == "integer") {
    tib_int(name, required = FALSE)
  } else if (type == "boolean") {
    tib_lgl(name, required = FALSE)
  } else if (type == "number") {
    tib_dbl(name, required = FALSE)
  } else if (type == "variant") {
    tib_variant(name, required = FALSE)
  } else {
    cli_abort("Unsupported type")
  }
}

# # Explanation for `allOf`, `oneOf`, and `anyOf`
# # https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/
handle_all_of <- function(schema, name, openapi_spec) {
  # must satisfy all the schemas -> combine them
  out <- purrr::map(schema$allOf, ~ parse_schema(.x, name, openapi_spec))
  # TODO fix `call`
  tib_combine(out, name, current_call())
}

handle_all_of_tspec <- function(schema, openapi_spec) {
  # must satisfy all the schemas -> combine them
  out <- purrr::map(schema$allOf, ~ schema_to_tspec(.x, openapi_spec))
  tspec_combine(!!!out)
}

handle_one_of <- function(schema, name, openapi_spec) {
  out <- purrr::map(schema$oneOf, ~ parse_schema(.x, name, openapi_spec))
  # must satisfy one of the schemas
  # for now simply try to combine them...
  tryCatch({
    # TODO fix `call`
    tib_combine(out, name, current_call())
  }, error = function(cnd) {
    tib_variant(name, required = FALSE)
  })
}

handle_one_of_tspec <- function(schema, openapi_spec) {
  out <- purrr::map(schema$oneOf, ~ schema_to_tspec(.x, openapi_spec))
  # must satisfy one of the schemas
  # for now simply try to combine them...
  tryCatch({
    tspec_combine(!!!out)
  }, error = function(cnd) {
    browser()
    tib_variant()
  })
}

if (is_installed("memoise")) {
  parse_schema_memoised <- memoise::memoise(parse_schema, omit_args = "openapi_spec")
} else {
  parse_schema_memoised <- parse_schema
}
