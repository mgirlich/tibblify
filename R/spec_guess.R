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
#' @param arg An argument name as a string. This argument will be mentioned in
#'   error messages as the input that is at the origin of a problem.
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
  check_bool(empty_list_unspecified, call = call)
  check_bool(simplify_list, call = call)
  check_bool(inform_unspecified, call = call)

  if (is.data.frame(x)) {
    guess_tspec_df(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      inform_unspecified = inform_unspecified,
      call = call
    )
  } else if (vec_is_list(x)) {
    guess_tspec_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      inform_unspecified = inform_unspecified,
      call = call
    )
  } else {
    stop_input_type(
      x,
      c("a data frame", "a list"),
      arg = caller_arg(x),
      call = call
    )
  }
}

guess_tspec_list <- function(x,
                             ...,
                             empty_list_unspecified = FALSE,
                             simplify_list = FALSE,
                             inform_unspecified = should_inform_unspecified(),
                             arg = caller_arg(x),
                             call = current_call()) {
  check_dots_empty()
  check_bool(empty_list_unspecified, call = call)
  check_bool(simplify_list, call = call)
  check_bool(inform_unspecified, call = call)

  check_list(x)
  if (is_empty(x)) {
    msg <- "{.arg {arg}} must not be empty."
    cli::cli_abort(msg, call = call)
  }

  # if `x` is both, an object list and an object, it should be very rare that
  # it should be parsed as an object.
  if (is_object_list(x)) {
    spec <- guess_tspec_object_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      call = call
    )
  } else if (is_object(x)) {
    spec <- guess_tspec_object(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      call = call
    )
  } else {
    abort_not_tibblifiable(x, arg, call)
  }

  if (inform_unspecified) spec_inform_unspecified(spec)

  spec
}

guess_make_tib_df <- function(name,
                              values_flat,
                              empty_list_unspecified,
                              simplify_list) {
  check_list(values_flat)

  fields <- guess_object_list_spec(values_flat, empty_list_unspecified, simplify_list)
  names_to <- if (is_named(values_flat) && !is_empty(values_flat)) ".names"

  tib_df(name, !!!fields, .names_to = names_to)
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
