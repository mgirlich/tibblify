is_object <- function(x) {
  if (identical(x, list())) {
    return(TRUE)
  }

  # TODO not sure if it is necessary to be that strict
  if (!vec_is_list(x)) {
    return(FALSE)
  }

  # TODO use `is_named2()` once new rlang version is released
  if (!is_named(x) && !is_empty(x)) {
    return(FALSE)
  }

  x_names <- names2(x)
  if (vec_duplicate_any(x_names)) {
    return(FALSE)
  }

  # TODO upper limit on width of object?
  TRUE
}

is_object_list <- function(x) {
  if (identical(x, list())) {
    return(TRUE)
  }

  if (is.data.frame(x)) {
    return(TRUE)
  }

  if (!vec_is_list(x)) {
    return(FALSE)
  }

  has_non_object_elements <- any(purrr::map_lgl(x, ~ !is.null(.x) && !is_object(.x)))
  if (has_non_object_elements) {
    return(FALSE)
  }

  TRUE
}

is_object_list2 <- function(x) {
  n <- vec_size(x)
  if (n == 1) return(FALSE)

  x <- unname(x)
  all_names <- vec_c(!!!lapply(x, names), .ptype = character())
  names_count <- vec_count(all_names, "location")

  any(names_count$count >= 0.9 * n)
}
