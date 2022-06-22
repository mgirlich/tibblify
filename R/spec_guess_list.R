#' @rdname spec_guess
#' @export
spec_guess_list <- function(x,
                            empty_list_unspecified = FALSE,
                            simplify_list = FALSE,
                            call = current_call()) {
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

  if (is_object_list(x)) {
    spec <- spec_guess_object_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list,
      call = call
    )
    return(spec)
  }

  if (is_object(x)) {
    spec <- spec_guess_object(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list,
      call = call
    )
    return(spec)
  }

  cli::cli_abort(c(
    "Cannot guess spec.",
    "v" = "The object is a list.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object_list()}.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object()}.",
    "i" = "Try to check the specs of the individual elements with {.code purrr::map(x, guess_spec)}."
  ))
}

guess_make_tib_df <- function(name,
                              values_flat,
                              required,
                              empty_list_unspecified,
                              simplify_list) {
  list_of_null <- all(purrr::map_lgl(values_flat, is_null))
  if (list_of_null) {
    if (is_named(values_flat) && !is_empty(values_flat)) {
        fields <- purrr::map(set_names(names(values_flat)), tib_unspecified)
        return(maybe_tib_row(name, fields, required))
      }

      return(tib_unspecified(name, required))
  }

  fields <- guess_object_list_spec(values_flat, empty_list_unspecified, simplify_list)
  names_to <- if (is_named(values_flat) && !is_empty(values_flat)) ".names"

  maybe_tib_df(name, fields, required, names_to = names_to)
}
