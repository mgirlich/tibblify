check_flag <- function(x, arg = caller_arg(x), call = caller_env()) {
  vctrs::vec_assert(x, logical(), size = 1L, arg = arg, call = call)

  if (is.na(x)) {
    cli::cli_abort("{.arg arg} must not be {.code NA}.", call = call)
  }
}

path_to_string <- function(path) {
  if (length(path) == 0) {
    return("<root>")
  }

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
  msg <- "Required element absent at path {path_str}."
  cli::cli_abort(msg)
}

stop_scalar <- function(path) {
  path_str <- path_to_string(path)
  msg <- "Element at path {path_str} must have size 1."
  cli::cli_abort(msg)
}

stop_duplicate_name <- function(path, name) {
  path_str <- path_to_string(path)
  msg <- "Element at path {path_str} has duplicate name {.val {name}}."
  cli::cli_abort(msg)
}

stop_empty_name <- function(path, index) {
  path_str <- path_to_string(path)
  msg <- "Element at path {path_str} has empty name at position {index + 1}."
  cli::cli_abort(msg)
}

stop_names_is_null <- function(path) {
  path_str <- path_to_string(path)
  msg <- "Element at path {path_str} has {.code NULL} names."
  cli::cli_abort(msg)
}

stop_object_vector_names_is_null <- function(path) {
  path_str <- path_to_string(path)
  msg <- c(
    "Element at path {path_str} has {.code NULL} names.",
    i = 'Element must be named for {.code tib_vector(input_form = "object")}.'
  )
  cli::cli_abort(msg)
}

stop_vector_non_list_element <- function(path, input_form) {
  # FIXME {.code} cannot be interpolated correctly
  path_str <- path_to_string(path)
  msg <- 'Element at path {path_str} must be a list for `input_form = "{input_form}"`'
  cli::cli_abort(msg)
}

stop_vector_wrong_size_element <- function(path, input_form) {
  path_str <- path_to_string(path)
  msg <- 'Each element in list at path {path_str} must have size 1.'
  cli::cli_abort(msg)
}

stop_colmajor_wrong_size_element <- function(path, size_exp, size_act) {
  path_str <- path_to_string(path)
  msg <- c(
    "Field at path {path_str} has size {.val {size_act}}, not size {.val {size_exp}}.",
    i = 'For {.code input_form = "colmajor"} each field must have the same size.'
  )
  cli::cli_abort(msg)
}

stop_colmajor_non_list_element <- function(path) {
  path_str <- path_to_string(path)
  msg <- 'Element at path {path_str} must be a list.'
  cli::cli_abort(msg)
}

vec_flatten <- function(x, ptype) {
  vctrs::vec_unchop(x, ptype = ptype)
}

list_drop_null <- function(x) {
  null_flag <- vec_equal_na(x)
  if (any(null_flag)) {
    x <- x[!null_flag]
  }

  x
}
