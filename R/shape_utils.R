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

  has_non_object_elements <- any(purrr::map_lgl(x, ~ !is.null(.x) && !is_object(.x)))
  if (has_non_object_elements) {
    return(FALSE)
  }

  TRUE
}

get_type <- function(x) {
  # TODO what about `list()`?
  if (is_object(x)) {
    return("object")
  }

  n_max <- 1e3
  if (vec_size(x) > n_max) {
    x <- vec_slice(x, seq(n_max))
  }

  if (is_object_list(x)) {
    return("object_list")
  }

  "list"
}
