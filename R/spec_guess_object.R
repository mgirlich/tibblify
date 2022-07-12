#' @rdname guess_tspec
#' @export
guess_tspec_object <- function(x,
                              ...,
                              empty_list_unspecified = FALSE,
                              simplify_list = FALSE,
                              call = rlang::current_call()) {
  check_dots_empty()
  withr::local_options(list(tibblify.used_empty_list_arg = NULL))
  if (is.data.frame(x)) {
    msg <- c(
      "{.arg x} must not be a dataframe.",
      i = "Did you want to use {.fn guess_tspec_df} instead?"
    )
    cli::cli_abort(msg, call = call)
  }

  if (!is.list(x)) {
    cls <- class(x)[[1]]
    msg <- "{.arg x} must be a list. Instead, it is a {.cls {cls}}."
    cli::cli_abort(msg, call = call)
  }

  check_object_names(x, call)

  if (is_empty(x)) {
    return(tspec_object())
  }

  fields <- purrr::imap(
    x,
    guess_object_field_spec,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  tspec_object(
    vector_allows_empty_list = is_true(getOption("tibblify.used_empty_list_arg")),
    !!!fields
  )
}

guess_object_field_spec <- function(value,
                                    name,
                                    empty_list_unspecified,
                                    simplify_list) {
  if (is_null(value)) {
    return(tib_unspecified(name))
  }

  if (identical(value, list()) || identical(value, set_names(list()))) {
    return(tib_unspecified(name))
  }

  value_type <- tib_type_of(value, name, other = TRUE)

  if (value_type == "other") {
    return(tib_variant(name))
  }

  if (value_type == "vector") {
    ptype <- tib_ptype(value)
    if (is_unspecified(ptype)) {
      return(tib_unspecified(name))
    }

    if (vec_size(value) == 1) {
      return(tib_scalar(name, ptype))
    } else {
      return(tib_vector(name, ptype))
    }
  }

  if (value_type == "df") {
    field_spec <- purrr::imap(value, col_to_spec, empty_list_unspecified)
    return(tib_df(name, !!!field_spec))
  }

  if (value_type != "list") {
    cli::cli_abort("{.fn tib_type_of} returned an unexpected type", .internal = TRUE) # nocov
  }

  if (is_object_list(value)) {
    spec <- guess_make_tib_df(
      name,
      values_flat = value,
      required = TRUE,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(spec)
  }

  if (simplify_list) {
    input_form_result <- guess_vector_input_form(value, name)
    if (input_form_result$can_simplify) {
      return(input_form_result$tib_spec)
    }
  }

  if (is_object(value)) {
    fields <- purrr::imap(
      value,
      guess_object_field_spec,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(tib_row(name, !!!fields))
  }

  tib_variant(name)
}

check_object_names <- function(x, call) {
  # TODO should this be more strict and also expect names for an empty list?
  if (!is_named2(x)) {
    msg <- "{.arg x} must be fully named."
    cli::cli_abort(msg, call = call)
  }

  x_nms <- names(x)
  if (vec_duplicate_any(x_nms)) {
    msg <- "Names of {.arg x} must be unique."
    cli::cli_abort(msg, call = call)
  }
}

guess_vector_input_form <- function(value, name) {
  ptype_result <- get_ptype_common(value, empty_list_unspecified = FALSE)
  if (!ptype_result$has_common_ptype) {
    return(list(can_simplify = FALSE))
  }

  ptype <- ptype_result$ptype
  if (is_null(ptype)) {
    if (is_named(value)) {
      return(list(can_simplify = FALSE))
    }

    tib_spec <- tib_unspecified(name, required = TRUE)
    return(list(can_simplify = TRUE, tib_spec = tib_spec))
  }

  if (!is_vec(ptype)) {
    return(list(can_simplify = FALSE))
  }

  if (is_field_scalar(value)) {
    if (is_named(value)) {
      tib_spec <- tib_vector(name, ptype, required = TRUE, input_form = "object")
    } else {
      tib_spec <- tib_vector(name, ptype, required = TRUE, input_form = "scalar_list")
    }

    return(list(can_simplify = TRUE, tib_spec = tib_spec))
  }

  list(can_simplify = TRUE, tib_spec = tib_variant(name, required = TRUE))
}
