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

  if (vec_size(x) <= 1 && is_object(x)) {
    return(FALSE)
  }

  names_list <- lapply(x, names)
  names_list <- list_drop_empty(names_list)
  n <- vec_size(names_list)

  if (n == 0) return(FALSE)

  all_names <- vec_unchop(names_list, ptype = character(), name_spec = "{inner}")
  names_count <- vec_count(all_names, "location")

  n_min <- floor(0.9 * n)
  any(names_count$count >= n_min) && mean(names_count$count >= 0.5)
}

list_drop_empty <- function(x) {
  # TODO when vctrs exports `list_drop_empty()`
  vec_slice(x, list_sizes(x) > 0)
}
