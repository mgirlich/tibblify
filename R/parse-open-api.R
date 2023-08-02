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
  # https://spec.openapis.org/oas/v3.1.0#openapi-object2
  openapi_spec <- read_spec(file)

  version <- openapi_spec$openapi
  if (is_null(version) || version < "3") {
    cli_abort("OpenAPI versions before 3 are not supported.")
  }
  # cannot use `openapi_spec` for memoising, as hashing it takes much more time
  # than everything else. To still make sure the result is correct simply forget
  # previous results.
  if (is_installed("memoise")) {
    memoise::forget(parse_schema_memoised)
  }

  out <- purrr::map(
    openapi_spec$paths,
    ~ {
      parse_path_item_object(
        path_item_object = .x,
        openapi_spec = openapi_spec
      )
    }
  )

  fast_tibble(
    list(
      endpoint = names2(out),
      operations = unname(out)
    )
  )
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
  if (is_list(file)) {
    file
  } else if (is_character(file)) {
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

parse_path_item_object <- function(path_item_object, openapi_spec) {
  # https://spec.openapis.org/oas/v3.1.0#path-item-object
  ops <- c("get", "put", "post", "delete", "options", "head", "patch", "trace")

  # TODO `ref`: Allows for a referenced definition of this path item. The
  # referenced structure MUST be in the form of a Path Item Object. In case a
  # Path Item Object field appears both in the defined object and the referenced
  # object, the behavior is undefined. See the rules for resolving Relative
  # References.

  # FIXME pass along `parameters`?
  parameters <- parse_parameters(path_item_object$parameters, openapi_spec)

  # TODO `summary`: An optional, string summary, intended to apply to all operations in this path.
  # TODO `description`: An optional, string description, intended to apply to all operations in this path. CommonMark syntax MAY be used for rich text representation.
  # TODO `parameters`: A list of parameters that are applicable for all the
  # operations described under this path. These parameters can be overridden at
  # the operation level, but cannot be removed there. The list MUST NOT include
  # duplicated parameters. A unique parameter is defined by a combination of a
  # name and location. The list can use the Reference Object to link to
  # parameters that are defined at the OpenAPI Object’s components/parameters.
  # if (has_name(path_item_object, "summary") ||
  #     has_name(path_item_object, "ref") ||
  #     has_name(path_item_object, "description")) {
  #   browser()
  # }

  operations <- path_item_object[intersect(names(path_item_object), ops)]
  parsed_operations <- purrr::map(operations, ~ parse_operation_object(.x, openapi_spec))
  out <- vctrs::vec_rbind(!!!parsed_operations, .names_to = "operation")
  if (nrow(out) > 0) {
    out$global_parameters <- list(parameters)
  } else {
    out$global_parameters <- list()
  }
  out
}

parse_operation_object <- function(operation_object, openapi_spec) {
  # https://spec.openapis.org/oas/v3.1.0#operation-object
  operation_object <- openapi_resolve_schema(operation_object, openapi_spec)

  spec <- tspec_object(
    tib_chr("summary", required = FALSE),
    tib_chr("description", required = FALSE),
    operation_id = tib_chr("operationId", required = FALSE),
    tib_chr_vec("tags", required = FALSE),
    tib_variant("parameters", required = FALSE),
    request_body = tib_variant("requestBody", required = FALSE),
    tib_variant("responses", required = FALSE),
    tib_lgl("deprecated", required = FALSE, fill = FALSE),
  )
  data <- tibblify(operation_object, spec)

  data$request_body <- list(parse_request_body(data$request_body, openapi_spec))
  data$parameters <- list(parse_parameters(data$parameters, openapi_spec))
  data$responses <- list(parse_responses_object(data$responses, openapi_spec))

  fast_tibble(unclass(data), n = 1L)
}

parse_request_body <- function(request_body, openapi_spec) {
  # https://spec.openapis.org/oas/v3.1.0#requestBodyObject
  if (is_null(request_body)) {
    return(NULL)
  }

  request_body <- openapi_resolve_schema(request_body, openapi_spec)

  # TODO add extensions?
  spec <- tspec_row(
    tib_chr("description", required = FALSE),
    tib_variant("content"),
    tib_lgl("required", required = FALSE, fill = FALSE)
  )
  parsed_request_body <- tibblify(request_body, spec)
  parsed_request_body$content[[1]] <- parse_media_type_objects(parsed_request_body$content[[1]], openapi_spec)

  parsed_request_body
}

parse_parameters <- function(parameters, openapi_spec) {
  # https://spec.openapis.org/oas/v3.1.0#parameter-object
  if (is_null(parameters)) {
    return(NULL)
  }

  parameters <- purrr::map(parameters, ~ openapi_resolve_schema(.x, openapi_spec))

  spec <- tspec_df(
    tib_chr("in"),
    tib_chr("name"),
    tib_chr("description", required = FALSE),
    tib_lgl("required", required = FALSE, fill = FALSE),
    tib_lgl("deprecated", required = FALSE, fill = FALSE),
    tib_lgl("allowEmptyValue", required = FALSE, fill = FALSE),
    # TODO can use `parse_schema()`?
    tib_row(
      "schema",
      tib_chr("type", required = FALSE),
      tib_chr("description", required = FALSE),
      # FIXME `enum` and `format` should go into a details column
      tib_chr_vec("enum", required = FALSE),
      tib_chr("format", required = FALSE),
      .required = FALSE
    ),
    # FIXME `explode` and `style` should go into a details column
    tib_lgl("explode", required = FALSE, fill = FALSE),
    tib_chr("style", required = FALSE),
  )

  tibblify(parameters, spec)
}

parse_responses_object <- function(responses_object, openapi_spec) {
  # https://spec.openapis.org/oas/v3.1.0#responsesObject
  responses_object <- purrr::map(responses_object, ~ openapi_resolve_schema(.x, openapi_spec))
  out <- purrr::map(responses_object, ~ parse_response_object(.x, openapi_spec))
  vctrs::vec_rbind(!!!out, .names_to = "status_code")
}

parse_response_object <- function(response_object, openapi_spec) {
  spec <- tspec_object(
    tib_chr("description"),
    tib_variant("headers", required = FALSE),
    tib_variant("content", required = FALSE),
    tib_variant("links", required = FALSE),
  )
  parsed_response <- tibblify(response_object, spec)

  if (!is_empty(parsed_response$headers)) {
    parsed_response$headers <- parse_header_objects(parsed_response$headers, openapi_spec)
  }
  # FIXME links
  if (!is_empty(parsed_response$links)) {
    browser()
  }
  parsed_response$content <- parse_media_type_objects(parsed_response$content, openapi_spec)

  parsed_response$headers <- list(parsed_response$headers)
  parsed_response$content <- list(parsed_response$content)
  parsed_response$links <- list(parsed_response$links)

  fast_tibble(parsed_response, n = 1L)
}

parse_media_type_objects <- function(media_type_objects, openapi_spec) {
  out <- purrr::map(media_type_objects, ~ parse_media_type_object(.x, openapi_spec))
  fast_tibble(
    list(media_type = names2(out), spec = unname(out)),
    n = length(out)
  )
}

parse_media_type_object <- function(media_type_object, openapi_spec) {
  schema_to_tspec(media_type_object$schema, openapi_spec)
}

parse_header_objects <- function(header_objects, openapi_spec) {
  # https://spec.openapis.org/oas/v3.1.0#headerObject
  # The Header Object follows the structure of the Parameter Object with the following changes:
  # * `name` MUST NOT be specified, it is given in the corresponding headers map.
  # * `in` MUST NOT be specified, it is implicitly in header.
  # * All traits that are affected by the location MUST be applicable to a location of header (for example, style).
  header_objects <- purrr::map(header_objects, ~ openapi_resolve_schema(.x, openapi_spec))

  spec <- tspec_df(
    .names_to = "name",
    tib_chr("description", required = FALSE),
    tib_lgl("required", required = FALSE, fill = FALSE),
    tib_lgl("deprecated", required = FALSE, fill = FALSE),
    tib_lgl("allowEmptyValue", required = FALSE, fill = FALSE),
    # TODO can use `parse_schema()`?
    tib_row(
      "schema",
      tib_chr("type", required = FALSE),
      tib_chr("description", required = FALSE),
      # FIXME `enum` and `format` should go into a details column
      tib_chr_vec("enum", required = FALSE),
      tib_chr("format", required = FALSE),
      .required = FALSE
    ),
    # FIXME `explode` and `style` should go into a details column
    tib_lgl("explode", required = FALSE, fill = FALSE),
    tib_chr("style", required = FALSE),
  )

  tibblify(header_objects, spec)
}

schema_to_tspec <- function(schema, openapi_spec) {
  schema <- openapi_resolve_schema(schema, openapi_spec)

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
    schema <- openapi_resolve_schema(schema$items, openapi_spec)

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
  for (field_name in intersect(required, names(fields))) {
    fields[[field_name]]$required <- TRUE
  }

  fields
}

openapi_resolve_schema <- function(schema, openapi_spec) {
  ref <- schema$`$ref`
  # FIXME this is probably quite a hack...
  ref <- ref %||% schema$allOf[[1]]$`$ref`
  if (!is.null(ref)) {
    ref_parts <- strsplit(ref, "/")[[1]]
    if (ref_parts[[1]] != "#") {
      cli_abort("{.field ref} does not start with {.value #}", .internal = TRUE)
    }
    schema <- purrr::chuck(openapi_spec, !!!ref_parts[-1])

    if (is.null(schema)) {
      cli_abort("No schema found for reference {.value {ref}}")
    }
  }

  if (has_name(schema, "$ref")) {
    schema <- openapi_resolve_schema(schema, openapi_spec)
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
  schema <- openapi_resolve_schema(schema, openapi_spec)
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
    if (!is.null(schema$additionalProperties)) {
      # FIXME hack required for asana which somehow has `additionalProperties = TRUE`
      # openapi_spec$components$schemas$RuleTriggerRequest$properties$action_data$additionalProperties
      if (is.list(schema$additionalProperties)) {
        additional_properties <- openapi_resolve_schema(schema$additionalProperties, openapi_spec)
      } else {
        additional_properties <- NULL
      }
    } else {
      additional_properties <- NULL
    }

    fields <- purrr::imap(c(schema$properties, additional_properties$properties), ~ parse_schema_memoised(.x, .y, openapi_spec))
    fields <- apply_required(fields, c(schema$required, additional_properties$required))
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

fast_tibble <- function(x, n = NULL) {
  vctrs::new_data_frame(x, n = n, class = c("tbl_df", "tbl"))
}
