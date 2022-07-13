check_flag <- function(x, arg = caller_arg(x), call = caller_env()) {
  vctrs::vec_assert(x, logical(), size = 1L, arg = arg, call = call)

  if (is.na(x)) {
    cli::cli_abort("{.arg arg} must not be {.code NA}.", call = call)
  }
}

format_path <- function(path_ptr) {
  paste0("x", path_to_string(get_path_data(path_ptr)))
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

path_to_string2 <- function(path) {
  if (is_empty(path)) {
    return("x")
  }

  paste0("x", path_to_string(path))
}

tibblify_abort <- function(..., .envir = caller_env()) {
  cli::cli_abort(..., class = "tibblify_error", .envir = .envir)
}

stop_required <- function(path) {
  n <- length(path)
  path_str <- path_to_string2(path[-n])
  msg <- c(
    "Field {.field {path[[n]]}} is required but does not exist in {.arg {path_str}}.",
    i = "Use {.code required = FALSE} if the field is optional."
  )
  tibblify_abort(msg)
}

stop_scalar <- function(path, size_act) {
  path_str <- path_to_string2(path)
  msg <- c(
    "{.arg {path_str}} must have size {.val 1}, not size {.val {size_act}}.",
    i = "You specified that the field is a scalar.",
    i = "Use {.fn tib_vector} if the field is a vector instead."
  )
  tibblify_abort(msg)
}

stop_duplicate_name <- function(path, name) {
  path_str <- path_to_string2(path)
  msg <- c(
    "The names of an object must be unique.",
    x = "{.arg {path_str}} has the duplicated name {.val {name}}."
  )
  tibblify_abort(msg)
}

stop_empty_name <- function(path, index) {
  path_str <- path_to_string2(path)
  msg <- c(
    "The names of an object can't be empty.",
    x = "{.arg {path_str}} has an empty name at location {index + 1}."
  )
  tibblify_abort(msg)
}

stop_names_is_null <- function(path) {
  path_str <- path_to_string2(path)
  msg <- c(
    "An object must be named.",
    x = "{.arg {path_str}} is not named."
  )
  tibblify_abort(msg)
}

stop_object_vector_names_is_null <- function(path) {
  path_str <- path_to_string(path)
  msg <- c(
    "Element at path {.field {path_str}} has {.code NULL} names.",
    i = 'Element must be named for {.code tib_vector(input_form = "object")}.'
  )
  tibblify_abort(msg)
}

stop_vector_non_list_element <- function(path, input_form) {
  # FIXME {.code} cannot be interpolated correctly
  path_str <- path_to_string(path)
  msg <- 'Element at path {path_str} must be a list for `input_form = "{input_form}"`'
  tibblify_abort(msg)
}

stop_vector_wrong_size_element <- function(path, input_form) {
  path_str <- path_to_string(path)
  msg <- 'Each element in list at path {path_str} must have size 1.'
  tibblify_abort(msg)
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

vec_flatten <- function(x, ptype, name_spec = zap()) {
  vctrs::vec_unchop(x, ptype = ptype, name_spec = name_spec)
}

list_drop_null <- function(x) {
  null_flag <- vec_equal_na(x)
  if (any(null_flag)) {
    x <- x[!null_flag]
  }

  x
}
