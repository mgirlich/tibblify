path_to_string <- function(path) {
  path_elements <- purrr::map_chr(
    path,
    function(elt) {
      if (is.character(elt)) {
        paste0("$", elt)
      } else {
        paste0("[[", elt + 1, "]]")
      }
    }
  )

  paste0(path_elements, collapse = "")
}

stop_required <- function(path) {
  path_str <- path_to_string(path)
  message <- c(
    paste0("Required element absent at path ", path_str)
  )
  abort(message)
}

stop_scalar <- function(path) {
  path_str <- path_to_string(path)
  message <- c(
    paste0("Element at path ", path_str, " must have size 1.")
  )
  abort(message)
}

stop_duplicate_name <- function(path) {
  path_str <- path_to_string(path)
  message <- c(
    paste0("Element at path ", path_str, " has duplicate name.")
  )
  abort(message)
}

stop_empty_name <- function(path) {
  path_str <- path_to_string(path)
  message <- c(
    paste0("Element at path ", path_str, " has empty name.")
  )
  abort(message)
}

stop_names_is_null <- function(path) {
  path_str <- path_to_string(path)
  message <- c(
    paste0("Element at path ", path_str, " has NULL names.")
  )
  abort(message)
}

vec_flatten <- function(x, ptype) {
  vctrs::vec_unchop(x, ptype = ptype)
}
