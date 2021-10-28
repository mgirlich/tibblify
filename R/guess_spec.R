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
      value = x,
      name = names(x)
    ),
    guess_field_spec,
    required = TRUE,
    object_list = FALSE
  )
}

guess_object_list_spec <- function(x) {
  required <- get_required(x)

  # need to remove empty elements for `purrr::transpose()` to work...
  non_empty_loc <- vctrs::list_sizes(x) != 0L
  x <- vec_slice(x, non_empty_loc)

  x_t <- purrr::transpose(unname(x), names(required))

  purrr::pmap(
    tibble::tibble(
      value = x_t,
      name = names(required),
      required = unname(required)
    ),
    guess_field_spec,
    object_list = TRUE
  )
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

guess_field_spec <- function(value, name, required, object_list) {
  if (object_list) {
    ptype_result <- safe_ptype_common2(value)
    no_common_ptype <- !is_null(ptype_result$error)

    if (no_common_ptype) return(tib_list(name, required))
    ptype <- ptype_result$result
  } else {
    ptype <- vec_ptype(value)
  }

  if (is_null(ptype)) return(tib_unspecified(name, required))

  if (!vec_is_list(ptype)) {
    if (guess_is_scalar(value, object_list)) {
      return(tib_scalar(name, ptype, required))
    } else {
      return(tib_vector(name, ptype, required))
    }
  }

  # `values` must be a list
  if (field_is_row(value, object_list)) {
    fields <- guess_get_field_spec(value, object_list)
    return(maybe_tib_row(name, fields, required))
  }

  if (object_list) {
    value_flat <- vec_unchop(value, ptype = ptype)
  } else {
    value_flat <- value
  }

  if (field_is_object_list(value_flat)) {
    return(guess_make_tib_df(name, value_flat, required))
  }

  # values2 <- vctrs::list_drop_empty(values)
  ptype_result <- safe_ptype_common2(value_flat)
  has_no_common_ptype <- !is_null(ptype_result$error)
  if (has_no_common_ptype) return(tib_list(name, required))

  ptype <- ptype_result$result
  # TODO inform?
  if (is_null(ptype)) return(tib_unspecified(name, required))

  list_of_scalars <- all(list_sizes(value_flat) == 1L)
  if (list_of_scalars) return(tib_vector(name, ptype, required, transform = make_unchop(ptype)))

  return(tib_list(name, required, transform = make_new_list_of(ptype)))
}

field_is_list <- function(value, ptype, object_list) {
  if (object_list) {
    vec_is_list(ptype)
  } else {
    vec_is_list(value)
  }
}

guess_is_scalar <- function(value, object_list) {
  if (object_list) {
    # TODO not sure about this...
    all(list_sizes(value) <= 1L)
  } else {
    vec_size(value) == 1L
  }
}

field_is_row <- function(value, object_list) {
  if (object_list) {
    is_object_list(value)
  } else {
    is_object(value)
  }
}

guess_get_field_spec <- function(value, object_list) {
  if (object_list) {
    fields <- guess_object_list_spec(value)
  } else {
    fields <- guess_object_spec(value)
  }
}

field_is_object_list <- function(values_flat) {
  is_object_list(values_flat)
}

guess_make_tib_df <- function(name, values_flat, required) {
  fields <- guess_object_list_spec(values_flat)
  names_to <- if (is_named(values_flat)) ".names"

  return(maybe_tib_df(name, fields, required, names_to = names_to))
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
