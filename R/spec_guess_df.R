#' @export
#' @rdname spec_guess
spec_guess_df <- function(x) {
  spec_df(
    !!!purrr::imap(x, col_to_spec)
  )
}

col_to_spec <- function(col, name) {
  if (is.data.frame(col)) {
    return(tib_row(name, !!!purrr::imap(col, col_to_spec)))
  }

  if (col_is_scalar(col)) {
    return(tib_scalar(name, vec_ptype(col)))
  }

  if (!is.list(col)) {
    cli::cli_abort("Column {name} is not a scalar but also not a list", .internal = TRUE)
  }

  # FIXME From here on this could use `spec_common()`
  # FIXME could use sampling for performance
  # * if `tib_unspecified()` it could use `vctrs::list_drop_empty()` to get
  #   non-empty element

  ptype_common <- get_ptype_common(col)
  if (!ptype_common$has_common_ptype) {
    return(tib_list(name))
  }

  ptype <- ptype_common$ptype
  if (is_null(ptype)) {
    return(tib_unspecified(name))
  }

  if (is.data.frame(ptype)) {
    # TODO calculate `.required`
    # see https://github.com/mgirlich/tibblify/issues/70
    col_flat <- vec_unchop(col)
    return(tib_df(name, !!!purrr::imap(col_flat, col_to_spec)))
  }

  return(tib_vector(name, ptype))
}

col_is_scalar <- function(x) {
  # `vec_is()` considers `list()` to be a vector but we don't
  if (vec_is_list(x)) {
    return(FALSE)
  }

  vec_is(x)
}

get_ptype_common <- function(x) {
  ptype_result <- purrr::safely(vec_ptype_common, quiet = TRUE)(!!!x)

  list(
    has_common_ptype = is_null(ptype_result$error),
    ptype = ptype_result$result
  )
}
