#' Guess the `tibblify()` Specification
#'
#' @param x A nested list.
#'
#' @return A specification object that can used in `tibblify()`.
#' @export
#'
#' @examples
#' guess_spec(list(x = 1, y = "a"))
#' guess_spec(list(list(x = 1), list(x = 2)))
#'
#' guess_spec(gh_users)
guess_spec <- function(x) {
  UseMethod("guess_spec")
}

#' @export
guess_spec.default <- function(x) {
  abort(paste0(
    "Cannot guess the specification for type ",
    vctrs::vec_ptype_full(x)
  ))
}


# data frame --------------------------------------------------------------

#' @export
guess_spec.data.frame <- function(x) {
  spec_df(
    !!!purrr::imap(x, col_to_spec)
  )
}

col_to_spec <- function(col, name) {
  if (is.data.frame(col)) {
    return(tib_row(name, !!!purrr::imap(col, col_to_spec)))
  }

  if (!is.list(col)) {
    return(tib_scalar(name, vec_ptype(col)))
  }

  ptype_safe <- safe_ptype_common2(col)
  if (!is_null(ptype_safe$error)) {
    return(tib_list(name))
  }

  ptype <- ptype_safe$result
  if (is_null(ptype)) {
    return(tib_unspecified(name))
  }

  if (is.data.frame(ptype)) {
    col_flat <- vec_unchop(col)
    return(tib_df(name, !!!purrr::imap(col_flat, col_to_spec)))
  }

  return(tib_vector(name, ptype))
}

safe_ptype_common2 <- function(x) {
  purrr::safely(vec_ptype_common, quiet = TRUE)(!!!x)
}


# list --------------------------------------------------------------------

#' @export
guess_spec.list <- function(x) {
  valid_object_list <- is_object_list(x)
  valid_object <- is_object(x)

  if (valid_object_list && !valid_object) {
    fields <- guess_object_list_spec(x)

    names_to <- NULL
    if (is_named(x)) {
      names_to <- ".names"
    }
    return(spec_df(!!!fields, .names_to = names_to))
  }

  if (valid_object) {
    fields <- guess_object_spec(x)
    return(spec_object(!!!fields))
  }

  abort("Cannot guess spec")
}


# list - object -----------------------------------------------------------

guess_object_spec <- function(x) {
  purrr::pmap(
    tibble::tibble(
      values = x,
      name = names(x)
    ),
    guess_object_field_spec
  )
}

guess_object_field_spec <- function(values, name) {
  if (is_null(values)) return(tib_unspecified(name))

  if (!vec_is_list(values)) {
    if (vec_size(values) == 1) {
      return(tib_scalar(name, vec_ptype(values)))
    }
    return(tib_vector(name, vec_ptype(values)))
  }

  # `values` must be a list
  if (is_object(values)) {
    fields <- guess_object_spec(values)
    return(maybe_tib_row(name, fields))
  }

  if (is_object_list(values)) {
    fields <- guess_object_list_spec(values)
    return(maybe_tib_df(name, fields, names_to = if (is_named(values)) ".names"))
  }

  # values2 <- vctrs::list_drop_empty(values)
  ptype_result <- safe_ptype_common2(values)
  has_no_common_ptype <- !is_null(ptype_result$error)
  if (has_no_common_ptype) return(tib_list(name))

  ptype <- ptype_result$result
  # TODO inform
  if (is_null(ptype)) return(tib_unspecified(name))

  list_of_scalars <- all(list_sizes(values) == 1L)
  if (list_of_scalars) return(tib_vector(name, ptype, transform = make_unchop(ptype)))

  return(tib_list(name, transform = make_new_list_of(ptype)))
}


# list - df ---------------------------------------------------------------

guess_object_list_spec <- function(x) {
  required <- get_required(x)

  # need to remove empty elements for `purrr::transpose()` to work...
  non_empty_loc <- vctrs::list_sizes(x) != 0L
  x <- vec_slice(x, non_empty_loc)

  x_t <- purrr::transpose(unname(x), names(required))

  purrr::pmap(
    tibble::tibble(
      values = x_t,
      name = names(required),
      required = unname(required)
    ),
    guess_object_list_field_spec
  )
}

guess_object_list_field_spec <- function(values, name, required) {
  ptype_result <- safe_ptype_common2(values)
  no_common_ptype <- !is_null(ptype_result$error)
  if (no_common_ptype) return(tib_list(name, required))

  ptype <- ptype_result$result
  # TODO inform
  if (is_null(ptype)) return(tib_unspecified(name, required))

  if (!is.list(ptype)) {
    sizes <- list_sizes(values)
    if (all(sizes <= 1)) {
      return(tib_scalar(name, ptype, required))
    } else {
      return(tib_vector(name, ptype, required))
    }
  }

  if (is_object_list(values)) {
    fields <- guess_object_list_spec(values)
    return(maybe_tib_row(name, fields, required = required))
  }


  values_flat <- vec_unchop(values, ptype = ptype)
  if (is_object_list(values_flat)) {
    fields <- guess_object_list_spec(values_flat)

    return(maybe_tib_df(name, required = required, fields, names_to = if (is_named(values_flat)) ".names"))
  }

  return(tib_list(name, required))
}

get_required <- function(x, sample_size = 10e3) {
  n <- vec_size(x)
  x <- unname(x)
  if (n > sample_size) {
    n <- sample_size
    x <- vec_slice(x, sample(n, sample_size))
  }

  all_names <- vec_c(!!!lapply(x, names), .ptype = character())
  names_count <- vec_count(all_names, "location")

  empty_loc <- lengths(x) == 0L
  if (any(empty_loc)) {
    rep_named(names_count$key, FALSE)
  } else {
    set_names(names_count$count == n, names_count$key)
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

  return(tib_row(name, !!!fields, .required = required))
}

maybe_tib_df <- function(name, fields, required = TRUE, names_to = NULL) {
  if (is_empty(fields) && is_null(names_to)) {
    return(tib_unspecified(name, required))
  }

  return(tib_df(name, !!!fields, .required = required, .names_to = names_to))
}
