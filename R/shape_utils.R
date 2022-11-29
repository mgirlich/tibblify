is_object <- function(x) {
  .Call(ffi_is_object, x)
}

should_guess_object <- function(x) {
  # TODO upper limit on width of object?
  .Call(ffi_is_object, x);
}

is_object_list <- function(x) {
  .Call(ffi_is_object_list, x)
}

should_guess_object_list <- function(x) {
  if (!.Call(ffi_is_object_list, x)) {
    return(FALSE)
  }

  # TODO why is this here?
  if (vec_size(x) <= 1 && is_object(x)) {
    return(FALSE)
  }

  names_list <- lapply(x, names)
  names_list <- vctrs::list_drop_empty(names_list)
  n <- vec_size(names_list)

  # TODO why is this here?
  if (n == 0) return(FALSE)

  all_names <- list_unchop(names_list, ptype = character(), name_spec = "{inner}")
  names_count <- vec_count(all_names, "location")

  n_min <- floor(0.9 * n)
  any(names_count$count >= n_min) && mean(names_count$count >= 0.5)
}
