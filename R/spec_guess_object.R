#' @rdname spec_guess
#' @export
spec_guess_object <- function(x, simplify_list = TRUE, call = current_env()) {
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

  fields <- guess_object_spec(x, simplify_list)
  return(spec_object(!!!fields))
}

guess_object_spec <- function(x, simplify_list) {
  purrr::pmap(
    tibble::tibble(
      value = x,
      name = names(x)
    ),
    guess_field_spec,
    required = TRUE,
    multi = FALSE,
    simplify_list = simplify_list
  )
}
