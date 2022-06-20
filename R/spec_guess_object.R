#' @rdname spec_guess
#' @export
spec_guess_object <- function(x, simplify_list = TRUE) {
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
