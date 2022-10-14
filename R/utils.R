check_flag <- function(x, arg = caller_arg(x), call = caller_env()) {
  vctrs::vec_assert(x, logical(), size = 1L, arg = arg, call = call)

  if (is.na(x)) {
    cli::cli_abort("{.arg arg} must not be {.code NA}.", call = call)
  }
}

format_path <- function(path_ptr) {
  path_to_string(get_path_data(path_ptr))
}

path_to_string <- function(path) {
  depth <- path[[1]] + 1L
  path_elts <- path[[2]]

  if (depth == 0) {
    return("x")
  }

  path_elements <- purrr::map_chr(
    path_elts[1:depth],
    function(elt) {
      if (is.character(elt)) {
        paste0("$", elt)
      } else {
        paste0("[[", elt + 1, "]]")
      }
    }
  )

  paste0("x", paste0(path_elements, collapse = ""))
}

tibblify_abort <- function(..., .envir = caller_env()) {
  cli::cli_abort(..., class = "tibblify_error", .envir = .envir)
}

stop_required <- function(path) {
  n <- path[[1]] + 1L
  path_elts <- path[[2]]
  path[[1]] <- path[[1]] - 1L
  path_str <- path_to_string(path)
  msg <- c(
    "Field {.field {path_elts[[n]]}} is required but does not exist in {.arg {path_str}}.",
    i = "Use {.code required = FALSE} if the field is optional."
  )
  tibblify_abort(msg)
}

stop_scalar <- function(path, size_act) {
  path_str <- path_to_string(path)
  msg <- c(
    "{.arg {path_str}} must have size {.val {1}}, not size {.val {size_act}}.",
    i = "You specified that the field is a scalar.",
    i = "Use {.fn tib_vector} if the field is a vector instead."
  )
  tibblify_abort(msg)
}

stop_duplicate_name <- function(path, name) {
  path_str <- path_to_string(path)
  msg <- c(
    "The names of an object must be unique.",
    x = "{.arg {path_str}} has the duplicated name {.val {name}}."
  )
  tibblify_abort(msg)
}

stop_empty_name <- function(path, index) {
  path_str <- path_to_string(path)
  msg <- c(
    "The names of an object can't be empty.",
    x = "{.arg {path_str}} has an empty name at location {index + 1}."
  )
  tibblify_abort(msg)
}

stop_names_is_null <- function(path) {
  path_str <- path_to_string(path)
  msg <- c(
    "An object must be named.",
    x = "{.arg {path_str}} is not named."
  )
  tibblify_abort(msg)
}

stop_object_vector_names_is_null <- function(path) {
  path_str <- path_to_string(path)
  msg <- c(
    'A vector must be a named list for {.code input_form = "object."}',
    x = "{.arg {path_str}} is not named."
  )
  tibblify_abort(msg)
}

# stop_vector_non_list_element <- function(path, input_form, x) {
stop_vector_non_list_element <- function(path, input_form, x) {
  # FIXME {.code} cannot be interpolated correctly
  path_str <- path_to_string(path)
  msg <- c(
    "{.arg {path_str}} must be a list, not {obj_type_friendly(x)}.",
    x = '`input_form = "{input_form}"` can only parse lists.',
    i = 'Use `input_form = "vector"` (the default) if the field is already a vector.'
  )
  tibblify_abort(msg)
}

stop_vector_wrong_size_element <- function(path, input_form, x) {
  path_str <- path_to_string(path)
  sizes <- list_sizes(x)
  idx <- which(sizes != 1)
  if (input_form == "scalar_list") {
    desc <- "a list of scalars"
  } else {
    desc <- "an object"
  }
  msg <- c(
    "{.arg {path_str}} is not {desc}.",
    x = "Element {.field {idx}} must have size {.val {1}}, not size {.val {sizes[idx]}}."
  )
  tibblify_abort(msg)
}

stop_colmajor_wrong_size_element <- function(path, size_exp, size_act) {
  n <- length(path)
  path_str <- path_to_string(path[-n])
  msg <- c(
    "Not all fields of {.arg {path_str}} have the same size.",
    x = "Field {.field {path[[n]]}} has size {.val {size_act}}.",
    x = "Other fields have size {.val {size_exp}}."
  )
  tibblify_abort(msg)
}

stop_colmajor_non_list_element <- function(path, x) {
  path_str <- path_to_string(path)
  msg <- c(
    "{.arg {path_str}} must be a list, not {obj_type_friendly(x)}."
  )
  tibblify_abort(msg)
}

vec_flatten <- function(x, ptype, name_spec = zap()) {
  vctrs::list_unchop(x, ptype = ptype, name_spec = name_spec)
}

list_drop_null <- function(x) {
  null_flag <- vec_detect_missing(x)
  if (any(null_flag)) {
    x <- x[!null_flag]
  }

  x
}
