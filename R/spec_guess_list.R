#' @rdname spec_guess
#' @export
spec_guess_list <- function(x,
                            empty_list_unspecified = FALSE,
                            simplify_list = TRUE,
                            call = current_call()) {
  if (vec_is(x) && !vec_is_list(x)) {
    cli::cli_abort(c(
      `!` = "{.arg x} must be a list.",
      "Instead, it is a vector with type <{vctrs::vec_ptype_full(x)}>"
    ))
  }

  if (!is.list(x)) {
    cli::cli_abort("{.arg x} must be a list")
  }

  if (is_empty(x)) {
    # TODO not completely sure about this
    return(spec_object())
  }

  if (is_object_list(x)) {
    spec <- spec_guess_object_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list,
      call = call
    )
    return(spec)
  }

  if (is_object(x)) {
    spec <- spec_guess_object(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list,
      call = call
    )
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

guess_field_spec <- function(value,
                             name,
                             required,
                             multi,
                             empty_list_unspecified,
                             simplify_list) {
  if (multi) {
    ptype_result <- get_ptype_common(value, empty_list_unspecified)

    # no common ptype -> it is a list of different types
    if (!ptype_result$has_common_ptype) return(tib_variant(name, required))
    ptype <- ptype_result$ptype
  } else {
    ptype <- vec_ptype(value)
    ptype <- special_ptype_handling(ptype)
  }

  # now we know the shape of value
  # scalar: ptype
  # multi: list_of<ptype>

  # only `NULL` -> no information about the actual type
  if (is_null(ptype) || inherits(ptype, "vctrs_unspecified")) {
    return(tib_unspecified(name, required))
  }

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
    spec <- guess_make_tib_df(
      name,
      values_flat = value_flat,
      required = required,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(spec)
  }

  if (is_field_row(value, multi, simplify_list)) {
    fields <- guess_get_field_spec(
      value,
      multi,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(maybe_tib_row(name, fields, required))
  }

  # values2 <- vctrs::list_drop_empty(values)
  ptype_result <- get_ptype_common(value_flat, empty_list_unspecified)
  if (!ptype_result$has_common_ptype) return(tib_variant(name, required))

  ptype <- ptype_result$ptype
  if (is_null(ptype)) return(tib_unspecified(name, required))
  if (identical(ptype, list()) || identical(ptype, set_names(list()))) return(tib_unspecified(name, required))

  if (!simplify_list) return(tib_variant(name, required))

  list_of_scalars <- all(list_sizes(value_flat) == 1L)
  if (list_of_scalars) return(tib_vector(name, ptype, required, transform = make_unchop(ptype)))

  return(tib_variant(name, required, transform = make_new_list_of(ptype)))
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

  # TODO change dummy value?
  ptype_result <- get_ptype_common(value, empty_list_unspecified = FALSE)
  if (!ptype_result$has_common_ptype) return(FALSE)

  ptype <- ptype_result$ptype
  !is_null(ptype) && !vec_is_list(ptype)
}

guess_get_field_spec <- function(value,
                                 multi,
                                 empty_list_unspecified,
                                 simplify_list) {
  if (multi) {
    fields <- guess_object_list_spec(
      value,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
  } else {
    fields <- guess_object_spec(
      value,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
  }
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

      return(tib_unspecified(name, required))
  }

  fields <- guess_object_list_spec(values_flat, empty_list_unspecified, simplify_list)
  names_to <- if (is_named(values_flat) && !is_empty(values_flat)) ".names"

  maybe_tib_df(name, fields, required, names_to = names_to)
}
