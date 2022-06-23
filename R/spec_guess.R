#' Guess the `tibblify()` Specification
#'
#' @param x A nested list.
#' @param simplify_list Try to simplify lists if possible?
#'
#' @return A specification object that can used in `tibblify()`.
#' @export
#'
#' @examples
#' guess_spec(list(x = 1, y = "a"))
#' guess_spec(list(list(x = 1), list(x = 2)))
#'
#' guess_spec(gh_users)
guess_spec <- function(x, simplify_list = TRUE, call = current_call()) {
  UseMethod("guess_spec")
}

#' @export
guess_spec.default <- function(x, simplify_list = TRUE, call = current_call()) {
  abort(paste0(
    "Cannot guess the specification for type ",
    vctrs::vec_ptype_full(x)
  ))
}


# data frame --------------------------------------------------------------

#' @export
guess_spec.data.frame <- function(x, simplify_list = TRUE, call = current_call()) {
  spec_df(
    !!!purrr::imap(x, col_to_spec, call)
  )
}

col_to_spec <- function(col, name, call) {
  if (is.data.frame(col)) {
    return(tib_row(name, !!!purrr::imap(col, col_to_spec, call)))
  }

  if (!is.list(col)) {
    return(tib_scalar(name, vec_ptype(col)))
  }

  # browser()
  # guess_spec(col)
  specs <- purrr::map(col, tib_guess, name)
  out <- try_fetch(
    tib_combine(specs, call),
    rlang_error = function(cnd) {
      tib_list(name)
    }
  )
  return(out)

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
    return(tib_df(name, !!!purrr::imap(col_flat, col_to_spec, call)))
  }

  return(tib_vector(name, ptype))
}

tib_guess <- function(x, key) {
  # TODO does this need `required` as argument?
  if (is_null(x)) {
    return(tib_unspecified(key))
  }

  if (is.data.frame(x)) {
    return(guess_spec(x))
  }

  if (vec_is_list(x)) {
    browser()
  }

  if (vec_is(x)) {
    return(tib_vector(key, x))
    # if (vec_size(x) == 1) {
    #   return(tib_scalar(key, x))
    # } else {
    #   return(tib_vector(key, x))
    # }
  }
}

safe_ptype_common2 <- function(x) {
  purrr::safely(vec_ptype_common, quiet = TRUE)(!!!x)
}


# list --------------------------------------------------------------------

#' @export
guess_spec.list <- function(x, simplify_list = TRUE, call = current_call()) {
  if (is_object_list(x)) return(guess_object_list(x, simplify_list))

  if (is_object(x)) return(guess_object(x, simplify_list))

  cli::cli_abort(c(
    "Cannot guess spec.",
    "v" = "The object is a list.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object_list()}.",
    "x" = "It doesn't meet the criteria of {.code tibblify:::is_object()}.",
    "i" = "Try to check the specs of the individual elements with {.code purrr::map(x, guess_spec)}."
  ))
}

guess_object_list <- function(x, simplify_list) {
  fields <- guess_object_list_spec(x, simplify_list)

  names_to <- NULL
  if (is_named(x)) {
    names_to <- ".names"
  }
  return(spec_df(!!!fields, .names_to = names_to))
}

guess_object <- function(x, simplify_list) {
  fields <- guess_object_spec(x, simplify_list)
  return(spec_object(!!!fields))
}


# list - object -----------------------------------------------------------

guess_object_spec <- function(x, simplify_list) {
  purrr::pmap(
    tibble(
      value = x,
      name = names(x)
    ),
    guess_field_spec,
    required = TRUE,
    multi = FALSE,
    simplify_list = simplify_list
  )
}

guess_object_list_spec <- function(x, simplify_list) {
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
    multi = TRUE,
    simplify_list = simplify_list
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

guess_field_spec <- function(value, name, required, multi,
                             simplify_list) {
  if (multi) {
    ptype_result <- safe_ptype_common2(value)
    no_common_ptype <- !is_null(ptype_result$error)

    # no common ptype -> it is a list of different types
    if (no_common_ptype) return(tib_list(name, required))
    ptype <- ptype_result$result
  } else {
    ptype <- vec_ptype(value)
  }

  # now we know the shape of value
  # scalar: ptype
  # multi: list_of<ptype>

  # only `NULL` -> no information about the actual type
  if (is_null(ptype)) return(tib_unspecified(name, required))

  # TODO what if `ptype` is not a vector?
  # TODO what if `ptype` is a data frame?
  # TODO matrix
  if (!vec_is_list(ptype)) {
    # every element must be a non-list vector
    if (is_field_scalar(value, multi)) {
      return(tib_scalar(name, ptype, required))
    } else {
      return(tib_vector(name, ptype, required))
    }
  }

  value_flat <- get_flat_value(value, ptype, multi)
  if (is_object_list(value_flat)) {
    return(guess_make_tib_df(name, value_flat, required, simplify_list))
  }

  if (is_field_row(value, multi, simplify_list)) {
    fields <- guess_get_field_spec(value, multi, simplify_list)
    return(maybe_tib_row(name, fields, required))
  }

  # values2 <- vctrs::list_drop_empty(values)
  ptype_result <- safe_ptype_common2(value_flat)
  has_no_common_ptype <- !is_null(ptype_result$error)
  if (has_no_common_ptype) return(tib_list(name, required))

  ptype <- ptype_result$result
  if (is_null(ptype)) return(tib_unspecified(name, required))

  if (!simplify_list) return(tib_list(name, required))

  list_of_scalars <- all(list_sizes(value_flat) == 1L)
  if (list_of_scalars) return(tib_vector(name, ptype, required, transform = make_unchop(ptype)))

  return(tib_list(name, required, transform = make_new_list_of(ptype)))
}

get_flat_value <- function(value, ptype, multi) {
  if (!multi) return(value)

  vec_unchop(value, ptype = ptype)
}

field_is_list <- function(value, ptype, object_list) {
  if (object_list) {
    vec_is_list(ptype)
  } else {
    vec_is_list(value)
  }
}

is_field_scalar <- function(value, multi) {
  if (multi) {
    # TODO not sure about this...
    all(list_sizes(value) <= 1L)
  } else {
    vec_size(value) == 1L
  }
}

is_field_row <- function(value, multi, simplify_list) {
  if (multi) {
    is_object_list(value)
  } else {
    if (can_flatten(value, simplify_list)) return(FALSE)
    is_object(value)
  }
}

can_flatten <- function(value, simplify_list) {
  if (!simplify_list) return(FALSE)

  ptype_result <- safe_ptype_common2(value)
  if (!is_null(ptype_result$error)) return(FALSE)

  ptype <- ptype_result$result
  !is_null(ptype) && !vec_is_list(ptype)
}

guess_get_field_spec <- function(value, multi, simplify_list) {
  if (multi) {
    fields <- guess_object_list_spec(value, simplify_list)
  } else {
    fields <- guess_object_spec(value, simplify_list)
  }
}

guess_make_tib_df <- function(name, values_flat, required, simplify_list) {
  list_of_null <- all(purrr::map_lgl(values_flat, is_null))
  if (list_of_null) {
    if (is_named(values_flat) && !is_empty(values_flat)) {
        fields <- purrr::map(set_names(names(values_flat)), tib_unspecified)
        return(maybe_tib_row(name, fields, required))
      }

      return(tib_unspecified(name, required))
  }

  fields <- guess_object_list_spec(values_flat, simplify_list)
  names_to <- if (is_named(values_flat) && !is_empty(values_flat)) ".names"

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
