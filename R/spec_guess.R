#' Guess the `tibblify()` Specification
#'
#' Use `guess_tspec()` if you don't know the input type.
#' Use `guess_tspec_df()` if the input is a data frame or an object list.
#' Use `guess_tspec_objecte()` is the input is an object.
#'
#' @param x A nested list.
#' @param ... These dots are for future extensions and must be empty.
#' @param empty_list_unspecified Treat empty lists as unspecified?
#' @param simplify_list Should scalar lists be simplified to vectors?
#' @param inform_unspecified Inform about fields whose type could not be
#'   determined?
#' @param call The execution environment of a currently running function, e.g.
#'   `caller_env()`. The function will be mentioned in error messages as the
#'   source of the error. See the `call` argument of [`abort()`] for more
#'   information.
#'
#' @return A specification object that can used in `tibblify()`.
#' @export
#'
#' @examples
#' guess_tspec(list(x = 1, y = "a"))
#' guess_tspec(list(list(x = 1), list(x = 2)))
#'
#' guess_tspec(gh_users)
guess_tspec <- function(x,
                        ...,
                        empty_list_unspecified = FALSE,
                        simplify_list = FALSE,
                        inform_unspecified = should_inform_unspecified(),
                        call = rlang::current_call()) {
  check_dots_empty()
  if (is.data.frame(x)) {
    guess_tspec_df(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      inform_unspecified = inform_unspecified,
      call = call
    )
  } else if (is.list(x)) {
    guess_tspec_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      inform_unspecified = inform_unspecified,
      call = call
    )
  } else {
    msg <- "Cannot guess the specification for type {vctrs::vec_ptype_full(x)}."
    cli::cli_abort(msg, call = call)
  }
}

guess_tspec_list <- function(x,
                             ...,
                             empty_list_unspecified = FALSE,
                             simplify_list = FALSE,
                             inform_unspecified = should_inform_unspecified(),
                             call = current_call()) {
  check_dots_empty()
  check_bool(empty_list_unspecified, call = call)
  check_bool(simplify_list, call = call)
  check_bool(inform_unspecified, call = call)

  check_list(x)
  if (is_empty(x)) {
    # TODO test this
    cli::cli_abort("Cannot guess spec for empty {.arg x}.")
  }

  if (should_guess_object_list(x)) {
    spec <- guess_tspec_object_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      call = call
    )
    if (inform_unspecified) spec_inform_unspecified(spec)
    return(spec)
  }

  if (is_object(x)) {
    spec <- guess_tspec_object(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      call = call
    )
    if (inform_unspecified) spec_inform_unspecified(spec)
    return(spec)
  }

  cli::cli_abort(c(
    "Cannot guess spec.",
    "v" = "The object is a list.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object_list()}.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object()}.",
    "i" = "Try to check the specs of the individual elements with {.code purrr::map(x, guess_spec)}."
  ))
}

guess_make_tib_df <- function(name,
                              values_flat,
                              required,
                              empty_list_unspecified,
                              simplify_list) {
  list_of_null <- all(purrr::map_lgl(values_flat, is_null))
  if (list_of_null) {
    if (is_named(values_flat) && !is_empty(values_flat)) {
      fields <- purrr::map(set_names(names(values_flat)), tib_unspecified)
      return(maybe_tib_row(name, fields, required))
    }

    return(tib_unspecified(name, required = required))
  }

  fields <- guess_object_list_spec(values_flat, empty_list_unspecified, simplify_list)
  names_to <- if (is_named(values_flat) && !is_empty(values_flat)) ".names"

  maybe_tib_df(name, fields, required, names_to = names_to)
}


# helpers -----------------------------------------------------------------

tib_ptype <- function(x) {
  ptype <- vec_ptype(x)
  special_ptype_handling(ptype)
}

is_unspecified <- function(x) {
  inherits(x, "vctrs_unspecified")
}

make_unchop <- function(ptype) {
  rlang::new_function(
    pairlist2(x = ),
    call2(sym("list_unchop"), x = sym("x"), ptype = ptype)
  )
}

make_new_list_of <- function(ptype) {
  rlang::new_function(
    pairlist2(x = ),
    call2(sym("new_list_of"), x = sym("x"), ptype = ptype)
  )
}

maybe_tib_row <- function(name, fields, required = TRUE) {
  if (is_empty(fields)) return(tib_unspecified(name, required))

  tib_row(name, !!!fields, .required = required)
}

maybe_tib_df <- function(name, fields, required = TRUE, names_to = NULL) {
  if (is_empty(fields) && is_null(names_to)) {
    return(tib_unspecified(name, required))
  }

  tib_df(name, !!!fields, .required = required, .names_to = names_to)
}

mark_empty_list_argument <- function(used_empty_list_arg) {
  if (is_true(used_empty_list_arg)) {
    options(tibblify.used_empty_list_arg = TRUE)
  }
}

#' Determine whether to inform about unspecified fields in spec
#'
#' Wrapper around `getOption("tibblify.show_unspecified")` that implements some
#' #' fall back logic if the option is unset. This returns:
#'
#' * `TRUE` if the option is set to `TRUE`
#' * `FALSE` if the option is set to `FALSE`
#' * `FALSE` if the option is unset and we appear to be running tests
#' * `TRUE` otherwise
#'
#' @return `TRUE` or `FALSE`.
#' @export
should_inform_unspecified <- function() {
  opt <- getOption("tibblify.show_unspecified", NA)
  if (is_true(opt)) {
    TRUE
  } else if (is_false(opt)) {
    FALSE
  } else if (is.na(opt) && is_testing()) {
    FALSE
  } else {
    TRUE
  }
}

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

spec_inform_unspecified <- function(spec, action = "inform", call = caller_env()) {
  unspecified_paths <- get_unspecfied_paths(spec)

  lines <- format_unspecified_paths(unspecified_paths)
  if (is_empty(lines)) return(spec)

  msg <- c(
    "The spec contains {length(lines)} unspecified field{?s}:",
    set_names(lines, "*"),
    "\n"
  )

  switch (action,
          inform = cli::cli_inform(msg),
          error = cli::cli_abort(msg, call = call)
  )

  invisible(spec)
}

format_unspecified_paths <- function(path_list, path = character()) {
  nms <- names(path_list)
  lines <- character()

  for (i in seq_along(path_list)) {
    nm <- nms[i]
    elt <- path_list[[i]]
    if (is.character(elt)) {
      new_lines <- paste0(path, cli::style_bold(nm))
    } else {
      new_path <- paste0(path, nm, "->")
      new_lines <- format_unspecified_paths(elt, path = new_path)
    }

    lines <- c(lines, new_lines)
  }

  lines
}

get_unspecfied_paths <- function(spec) {
  fields <- spec$fields
  unspecified_paths <- list()

  for (i in seq_along(fields)) {
    field <- fields[[i]]
    nm <- names(fields)[[i]]
    if (field$type == "unspecified") {
      unspecified_paths[[nm]] <- nm
    } else if (field$type %in% c("df", "row")) {
      sub_paths <- get_unspecfied_paths(field)
      unspecified_paths[[nm]] <- sub_paths
    }
  }

  unspecified_paths
}
