check_flag <- function(x, arg = caller_arg(x), call = caller_env()) {
  vctrs::vec_assert(x, logical(), size = 1L, arg = arg, call = call)

  if (is.na(x)) {
    cli::cli_abort("{.arg arg} must not be {.code NA}.", call = call)
  }
}

check_arg_different <- function(arg,
                                ...,
                                arg_name = caller_arg(arg),
                                call = caller_env()) {
  other_args <- dots_list(..., .named = TRUE)

  for (i in seq_along(other_args)) {
    if (identical(arg, other_args[[i]])) {
      other_arg_nm <- names(other_args)[[i]]
      msg <- "{.arg {arg_name}} must be different from {.arg {other_arg_nm}}."
      cli_abort(msg, call = call)
    }
  }
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

stop_colmajor_null <- function(path) {
  path_str <- path_to_string(path)
  msg <- c(
    "Field {.field {path_str}} must not be {.val NULL}."
  )
  tibblify_abort(msg)
}

stop_colmajor_no_size <- function(path) {
  tibblify_abort("Could not determine size.")
}

stop_colmajor_wrong_size_element <- function(path, size_act, path_exp, size_exp) {
  path_str <- path_to_string(path)
  path_str_exp <- path_to_string(path_exp)
  msg <- c(
    "Not all fields of {.arg x} have the same size.",
    x = "Field {.field {path_str}} has size {.val {size_act}}.",
    x = "Field {.field {path_str_exp}} has size {.val {size_exp}}."
  )
  tibblify_abort(msg)
}

stop_required_colmajor <- function(path) {
  n <- path[[1]] + 1L
  path_elts <- path[[2]]
  path[[1]] <- path[[1]] - 1L
  path_str <- path_to_string(path)
  msg <- c(
    "Field {.field {path_elts[[n]]}} is required but does not exist in {.arg {path_str}}.",
    i = 'For {.code .input_form = "colmajor"} every field is required.'
  )
  tibblify_abort(msg)
}

stop_non_list_element <- function(path, x) {
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
