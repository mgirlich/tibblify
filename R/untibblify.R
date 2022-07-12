#' Convert a data frame or object into a nested list
#'
#' The inverse operation to `tibblify()`. It converts a data frame or an object
#' into a nested list.
#'
#' @param x A data frame or an object.
#' @param spec Optional. A spec object which was used to create `x`.
#'
#' @return A nested list.
#' @export
#'
#' @examples
#' x <- tibble(
#'   a = 1:2,
#'   b = tibble(
#'     x = c("a", "b"),
#'     y = c(1.5, 2.5)
#'   )
#' )
#' untibblify(x)
untibblify <- function(x, spec = NULL) {
  call <- current_call()

  if (is.data.frame(x)) {
    untibblify_df(x, spec, call)
  } else if (vec_is_list(x)) {
    untibblify_list(x, spec, call)
  } else {
    cls <- class(x)[[1]]
    msg <- "{.arg x} must be a list. Instead, it is a {.cls {cls}}."
    cli::cli_abort(msg)
  }
}

untibblify_df <- function(x, spec, call) {
  if (is_null(spec)) {
    idx <- seq_len(vec_size(x))
    out <- purrr::map(idx, ~ untibblify_row(vec_slice(x, .x), spec, call))
    return(out)
  }

  idx <- seq_len(vec_size(x))
  purrr::map(idx, ~ untibblify_row(vec_slice(x, .x), spec, call))
}

untibblify_row <- function(x, spec, call) {
  if (!is_null(spec)) {
    x <- apply_spec_renaming(x, spec)
  }
  # browser()

  out <- as.list(x)
  fields <- spec$fields
  for (i in seq_along(out)) {
    elt <- x[[i]]
    if (is.data.frame(elt)) {
      out[[i]] <- untibblify_row(elt, fields[[i]], call)
    } else if (is.list(elt)) {
      tmp <- untibblify_list_elt(elt[[1]], fields[[i]], call)
      if (is_null(tmp)) {
        out[i] <- list(NULL)
      } else {
        out[[i]] <- tmp
      }
    } else {
      out[[i]] <- elt
    }
  }

  out
}

untibblify_list <- function(x, spec, call) {
  if (!is_null(spec)) {
    x <- apply_spec_renaming(x, spec)
  }

  fields <- spec$fields
  out <- x
  for (i in seq_along(x)) {
    out[[i]] <- untibblify_list_elt(x[[i]], fields[[i]], call)
  }

  out
}

untibblify_list_elt <- function(x, field_spec, call) {
  if (is.data.frame(x)) {
    untibblify_df(x, field_spec, call)
  } else {
    if (is_null(field_spec)) {
      return(x)
    }

    if (is_tib_row(field_spec)) {
      x <- new_data_frame(x, n = 1L)
      out <- untibblify_df(x, field_spec, call)
      return(out[[1]])
    }

    x
  }
}

apply_spec_renaming <- function(x, spec) {
  out <- list()
  fields <- spec$fields

  nms_map_inverted <- set_names(names(fields))
  for (i in seq_along(fields)) {
    nm <- names(fields)[[i]]
    key <- fields[[i]]$key
    if (length(key) > 1) {
      msg <- "{.fn untibblify} does not support specs with nested keys"
      cli::cli_abort(msg, call = call)
    }

    if (!is.character(key)) {
      msg <- "{.fn untibblify} does not support specs with non-character keys"
      cli::cli_abort(msg, call = call)
    }

    out[[key]] <- x[[nm]]
  }

  out
}
