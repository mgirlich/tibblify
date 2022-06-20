#' @rdname spec_guess
#' @export
spec_guess_list <- function(x, simplify_list = TRUE) {
  if (vec_is(x) && !vec_is_list(x)) {
    cli::cli_abort(c(
      `!` = "{.arg x} must be a list.",
      "Instead, it is a vector with type <{vctrs::vec_ptype_full(x)}>"
    ))
  }

  if (!is.list(x)) {
    cli::cli_abort("{.arg x} must be a list")
  }

  if (is_empty(x)) {
    # TODO not completely sure about this
    return(spec_object())
  }

  if (is_object_list(x)) return(spec_guess_object_list(x, simplify_list))

  if (is_object(x)) return(spec_guess_object(x, simplify_list))

  cli::cli_abort(c(
    "Cannot guess spec.",
    "v" = "The object is a list.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object_list()}.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object()}.",
    "i" = "Try to check the specs of the individual elements with {.code purrr::map(x, guess_spec)}."
  ))
}
