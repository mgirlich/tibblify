#' @rdname spec_guess
#' @export
spec_guess_object <- function(x,
                              ...,
                              empty_list_unspecified = FALSE,
                              simplify_list = FALSE,
                              call = current_call()) {
  check_dots_empty()
  if (is.data.frame(x)) {
    msg <- c(
      "{.arg x} must not be a dataframe.",
      i = "Did you want to use {.fn spec_guess_df} instead?"
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
    return(spec_object())
  }

  fields <- purrr::imap(
    x,
    guess_object_field_spec,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  spec_object(!!!fields)
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
    cli::cli_abort("{.fn tib_type_of} returned an unexpected type", .internal = TRUE)
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
    cli::cli_abort("`simplify_list = TRUE` is not yet supported", call = call)
    # TODO check if it is an enlisted vector
    # ptype_result <- get_ptype_common(value, empty_list_unspecified)
    # if (!ptype_result$has_common_ptype) return(tib_variant(name, required))
    #
    # ptype <- ptype_result$ptype
    # if (is_null(ptype)) return(tib_unspecified(name, required))
    # if (identical(ptype, list()) || identical(ptype, set_names(list()))) return(tib_unspecified(name, required))
    #
    # if (!simplify_list) return(tib_variant(name, required))
    #
    # list_of_scalars <- all(list_sizes(value_flat) == 1L)
    # if (list_of_scalars) return(tib_vector(name, ptype, required, transform = make_unchop(ptype)))
    #
    # return(tib_variant(name, required, transform = make_new_list_of(ptype)))
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
