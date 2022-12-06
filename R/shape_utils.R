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

is_list_of_object_lists <- function(x) {
  for (x_i in x) {
    if (!is_object_list(x_i) && !is.null(x_i)) {
      return(FALSE)
    }
  }

  TRUE
}

is_list_of_null <- function(x) {
  all(purrr::map_lgl(x, is_null))
}

list_is_list_of_null <- function(x) {
  all(purrr::map_lgl(x, is_list_of_null))
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

get_overview <- function(x) {
  classes <- purrr::map_chr(x, ~ class(.x)[1])
  paste0("  ", names(classes), ": ", classes, collapse = "\n")
}

guess_type <- function(x,
                       arg = caller_arg(x),
                       error_call = caller_env()) {
  object <- is_object(x)
  object_list <- is_object_list(x)

  if (object && object_list) {
    if (!is_interactive()) {
      # TODO should show name
      msg <- c(
        "Can't guess type of {.arg {arg}}.",
        x = "It is both an object and a named list of objects.",
        i = "Provide a spec to {.fn tibblify} or use {.fn guess_spec} interactively."
      )
      cli::cli_abort(msg, call = error_call)
    }

    return(choose_type(x, arg))
  }

  if (is_object(x)) {
    return("object")
  }

  if (is_object_list(x)) {
    return("object list")
  }

  abort_not_tibblifiable(x, arg, error_call)
}

abort_not_tibblifiable <- function(x,
                                   arg = caller_arg(x),
                                   error_call = caller_env()) {
  lgl_to_bullet <- function(x) {
    bullets <- c("x", "v")
    x2 <- as.integer(x) + 1L
    bullets[x2]
  }

  object_cnd <- c(
    "An object",
    "is a list,",
    "is fully named,",
    "and has unique names."
  )
  object_bullets <- lgl_to_bullet(c(vec_is_list(x), is_named2(x), anyDuplicated(names(x)) == 0))
  o_msg <- set_names(object_cnd, c("", object_bullets))

  object_list_cnd <- c(
    "A list of objects is",
    "a data frame or",
    "a list and",
    "each element is {.code NULL} or an object."
  )
  object_list_bullets <- lgl_to_bullet(c(
    is.data.frame(x),
    vec_is_list(x),
    purrr::detect_index(x, ~ !is.null(.x) && !is_object(.x)) == 0
  ))
  ol_msg <- set_names(object_list_cnd, c("", object_list_bullets))

  msg <- c(
    "{.arg {arg}} is neither an object nor a list of objects.",
    o_msg,
    ol_msg
  )

  cli::cli_abort(msg, call = error_call)
}

choose_type <- function(x, arg) {
  n <- length(x)
  if (n > 3) {
    x <- x[1:3]
  }

  # TODO nicer overview
  overviews <- purrr::map_chr(x, get_overview)
  x_overview <- paste0(names(x), "\n", overviews, collapse = "\n")

  msg <- c(
    "{.arg {arg}} is an object and a named object list.",
    "The structure of {.arg {arg}} is:"
  )
  cli::cli_alert_info(msg)
  inform(x_overview)

  title <- cli::format_message("How do you want to parse {.arg {arg}}?")
  choice <- menu(c("object", "object list"), title = title)
  return(choice)
}
