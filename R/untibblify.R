untibblify <- function(x) {
  if (is.data.frame(x)) {
    untibblify_df(x)
  } else if (vec_is_list(x)) {
    untibblify_list(x)
  } else {
    cls <- class(x)[[1]]
    msg <- "{.arg x} must be a list. Instead, it is a {.cls {cls}}."
    cli::cli_abort(msg)
  }
}

untibblify_df <- function(x) {
  idx <- seq_len(vec_size(x))
  purrr::map(idx, ~ untibblify_row(vec_slice(x, .x)))
}

untibblify_row <- function(x) {
  out <- as.list(x)
  is_df <- purrr::map_lgl(out, is.data.frame)
  out[is_df] <- purrr::map(out[is_df], untibblify_row)

  is_list <- purrr::map_lgl(out, is.list) & !is_df
  out[is_list] <- purrr::map(out[is_list], ~ untibblify_list_elt(.x[[1]]))

  out
}

untibblify_list <- function(x) {
  purrr::map(x, untibblify_list_elt)
}

untibblify_list_elt <- function(x) {
  if (is.data.frame(x)) {
    untibblify_df(x)
  } else {
    x
  }
}
