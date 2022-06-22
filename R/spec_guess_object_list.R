#' @rdname spec_guess
#' @export
spec_guess_object_list <- function(x,
                                   empty_list_unspecified = FALSE,
                                   simplify_list = FALSE,
                                   call = current_call()) {
  if (is.data.frame(x)) {
    msg <- c(
      "{.arg x} must not be a dataframe.",
      i = "Did you want to use {.fn spec_guess_df} instead?"
    )
    cli::cli_abort(msg, call = call)
  }

  if (!is.list(x)) {
    cls <- class(x)[[1]]
    msg <- "{.arg x} must be a list. Instead, it is a {.cls {cls}}."
    cli::cli_abort(msg, call = call)
  }

  fields <- guess_object_list_spec(
    x,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  names_to <- NULL
  if (is_named(x)) {
    names_to <- ".names"
  }

  spec_df(!!!fields, .names_to = names_to)
}

guess_object_list_spec <- function(x,
                                   empty_list_unspecified,
                                   simplify_list) {
  required <- get_required(x)

  # need to remove empty elements for `purrr::transpose()` to work...
  x <- vctrs::list_drop_empty(x)

  x_t <- purrr::transpose(unname(x), names(required))

  purrr::pmap(
    tibble::tibble(
      value = x_t,
      name = names(required),
      required = unname(required)
    ),
    guess_object_list_field_spec,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )
}

guess_object_list_field_spec <- function(value,
                                         name,
                                         required,
                                         empty_list_unspecified,
                                         simplify_list) {
  ptype_result <- get_ptype_common(value, empty_list_unspecified)

  # no common ptype can be one of two reasons:
  # * it contains non-vector elements
  # * it contains incompatible types
  # in both cases `tib_variant()` is used
  if (!ptype_result$has_common_ptype) {
    return(tib_variant(name, required))
  }

  # now we know that every element essentially has type `ptype`
  ptype <- ptype_result$ptype
  if (is_null(ptype)) {
    return(tib_unspecified(name, required))
  }

  ptype_type <- tib_type_of(ptype, name, other = FALSE)
  if (ptype_type == "vector") {
    if (is_field_scalar(value)) {
      return(tib_scalar(name, ptype, required))
    } else {
      return(tib_vector(name, ptype, required))
    }
  }

  if (ptype_type == "df") {
    # TODO should this actually be supported?
    cli::cli_abort("a list of dataframes is not yet supported", call = call)
  }

  if (ptype_type != "list") {
    cli::cli_abort("{.fn tib_type_of} returned an unexpected type", .internal = TRUE)
  }

  value_flat <- vec_flatten(value, ptype)
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

  if (is_field_row(value)) {
    fields <- guess_object_list_spec(
      value,
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

is_field_scalar <- function(value) {
  sizes <- list_sizes(value)
  if (any(sizes > 1)) {
    return(FALSE)
  }

  size_0_is_null <- vec_equal_na(value[sizes == 0])
  if (all(size_0_is_null)) {
    return(TRUE)
  }

  FALSE
}

is_field_row <- function(value) {
  is_object_list(value)
}
