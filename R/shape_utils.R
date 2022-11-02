is_object <- function(x) {
  if (identical(x, list())) {
    return(TRUE)
  }

  # TODO not sure if it is necessary to be that strict
  if (!vec_is_list(x)) {
    return(FALSE)
  }

  if (!is_named2(x)) {
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

  idx_non_object_elements <- purrr::detect_index(x, ~ !is.null(.x) && !is_object(.x))
  if (idx_non_object_elements != 0) {
    return(FALSE)
  }

  if (vec_size(x) <= 1 && is_object(x)) {
    return(FALSE)
  }

  names_list <- lapply(x, names)
  names_list <- vctrs::list_drop_empty(names_list)
  n <- vec_size(names_list)

  if (n == 0) return(FALSE)

  all_names <- list_unchop(names_list, ptype = character(), name_spec = "{inner}")
  names_count <- vec_count(all_names, "location")

  n_min <- floor(0.9 * n)
  any(names_count$count >= n_min) && mean(names_count$count >= 0.5)
}
