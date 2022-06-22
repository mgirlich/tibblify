#' @rdname spec_guess
#' @export
spec_guess_object <- function(x,
                              empty_list_unspecified = FALSE,
                              simplify_list = FALSE,
                              call = current_call()) {
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

  fields <- guess_object_spec(
    x,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  spec_object(!!!fields)
}

guess_object_spec <- function(x, empty_list_unspecified, simplify_list) {
  purrr::pmap(
    tibble::tibble(
      value = x,
      name = names(x)
    ),
    guess_field_spec,
    required = TRUE,
    multi = FALSE,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )
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
