#' @rdname spec_guess
#' @export
spec_guess_object_list <- function(x,
                                   empty_list_unspecified = FALSE,
                                   simplify_list = FALSE,
                                   call = current_call()) {
  fields <- guess_object_list_spec(
    x,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  names_to <- NULL
  if (is_named(x)) {
    names_to <- ".names"
  }

  spec_df(!!!fields, .names_to = names_to)
}

guess_object_list_spec <- function(x,
                                   empty_list_unspecified,
                                   simplify_list) {
  required <- get_required(x)

  # need to remove empty elements for `purrr::transpose()` to work...
  x <- vctrs::list_drop_empty(x)

  x_t <- purrr::transpose(unname(x), names(required))

  purrr::pmap(
    tibble::tibble(
      value = x_t,
      name = names(required),
      required = unname(required)
    ),
    guess_field_spec,
    multi = TRUE,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )
}

get_required <- function(x, sample_size = 10e3) {
  n <- vec_size(x)
  x <- unname(x)
  if (n > sample_size) {
    n <- sample_size
    x <- vec_slice(x, sample(n, sample_size))
  }

  all_names <- vec_c(!!!lapply(x, names), .ptype = character())
  names_count <- vec_count(all_names, "location")

  empty_loc <- lengths(x) == 0L
  if (any(empty_loc)) {
    rep_named(names_count$key, FALSE)
  } else {
    set_names(names_count$count == n, names_count$key)
  }
}
