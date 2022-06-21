#' Guess the `tibblify()` Specification
#'
#' @param x A nested list.
#' @param empty_list_unspecified Treat empty lists as unspecified?
#' @param simplify_list Try to simplify lists if possible?
#' @param call The execution environment of a currently running function, e.g.
#'   `caller_env()`. The function will be mentioned in error messages as the
#'   source of the error. See the `call` argument of [`abort()`] for more
#'   information.
#'
#' @return A specification object that can used in `tibblify()`.
#' @export
#'
#' @examples
#' spec_guess(list(x = 1, y = "a"))
#' spec_guess(list(list(x = 1), list(x = 2)))
#'
#' spec_guess(gh_users)
spec_guess <- function(x, empty_list_unspecified = FALSE, call = current_call()) {
  if (is.data.frame(x)) {
    spec_guess_df(
      x,
      empty_list_unspecified = empty_list_unspecified,
      call = call
    )
  } else if (is.list(x)) {
    spec_guess_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      call = call
    )
  } else {
    abort(paste0(
      "Cannot guess the specification for type ",
      vctrs::vec_ptype_full(x)
    ))
  }
}

# helpers -----------------------------------------------------------------

make_unchop <- function(ptype) {
  rlang::new_function(
    pairlist2(x = ),
    call2(sym("vec_unchop"), x = sym("x"), ptype = ptype)
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
