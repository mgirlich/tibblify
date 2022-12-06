# Guess the specification of an object list
# The caller has to make sure that `x` is really a list of objects!
guess_tspec_object_list <- function(x,
                                   ...,
                                   empty_list_unspecified = FALSE,
                                   simplify_list = FALSE,
                                   arg = caller_arg(x),
                                   call = current_call()) {
  check_dots_empty()
  check_list(x)

  withr::local_options(list(tibblify.used_empty_list_arg = NULL))

  fields <- guess_object_list_spec(
    x,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  tspec_df(
    !!!fields,
    .names_to = if (is_named(x)) ".names",
    vector_allows_empty_list = is_true(getOption("tibblify.used_empty_list_arg"))
  )
}

guess_object_list_spec <- function(object_list,
                                   empty_list_unspecified,
                                   simplify_list) {
  required <- get_required(object_list)

  # need to remove empty elements for `purrr::transpose()` to work...
  object_list <- vctrs::list_drop_empty(object_list)
  x_t <- purrr::transpose(unname(object_list), names(required))

  fields <- purrr::map2(
    x_t,
    names(required),
    function(value, name) {
      guess_object_list_field_spec(
        value,
        name,
        empty_list_unspecified = empty_list_unspecified,
        simplify_list = simplify_list
      )
    }
  )

  update_required_fields(fields, required)
}

update_required_fields <- function(fields, required) {
  for (field_name in names(required)) {
    fields[[field_name]]$required <- required[[field_name]]
  }

  fields
}

guess_object_list_field_spec <- function(value,
                                         name,
                                         empty_list_unspecified,
                                         simplify_list) {
  ptype_result <- get_ptype_common(value, empty_list_unspecified)

  # no common ptype can be one of two reasons:
  # * it contains non-vector elements
  # * it contains incompatible types
  # in both cases `tib_variant()` is used
  if (!ptype_result$has_common_ptype) {
    return(tib_variant(name))
  }

  # now we know that every element essentially has type `ptype`
  ptype <- ptype_result$ptype
  if (is_null(ptype)) {
    return(tib_unspecified(name))
  }

  ptype_type <- tib_type_of(ptype, name, other = FALSE)
  if (ptype_type == "vector") {
    out <- guess_object_list_vector_spec(value, name, ptype, ptype_result$had_empty_lists)
    return(out)
  }

  if (ptype_type == "df") {
    # TODO should this actually be supported?
    # TODO fix error call?
    cli::cli_abort("a list of dataframes is not yet supported")
  }

  # every element is a list or NULL at this point
  if (all(list_sizes(value) == 0)) {
    return(tib_unspecified(name))
  }

  if (list_is_list_of_null(value)) {
    return(tib_unspecified(name))
  }

  object <- is_object_list(value)
  object_list <- is_list_of_object_lists(value)

  if (object_list && object) {
    # TODO return `tib_undecided(c("row", "df"))`
    # choice <- user_choose_row_or_df(
    #   name,
    #   value_flat,
    #   empty_list_unspecified = empty_list_unspecified,
    #   simplify_list = simplify_list
    # )

    object <- FALSE
  }

  value_flat <- vec_flatten(value, list(), name_spec = NULL)
  if (object_list) {
    spec <- guess_make_tib_df(
      name,
      values_flat = value_flat,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(spec)
  }

  if (!simplify_list) {
    if (object) {
      fields <- guess_object_list_spec(
        value,
        empty_list_unspecified = empty_list_unspecified,
        simplify_list = simplify_list
      )
      return(maybe_tib_row(name, fields))
    }

    return(tib_variant(name))
  }

  ptype_result <- get_ptype_common(value_flat, empty_list_unspecified)
  could_be_vector <- ptype_result$has_common_ptype && is_field_scalar(value_flat)

  if (could_be_vector) {
    if (is_named(value_flat)) {
      return(tib_vector(name, ptype_result$ptype, input_form = "object"))
    } else {
      return(tib_vector(name, ptype_result$ptype, input_form = "scalar_list"))
    }
  }

  if (object) {
    fields <- guess_object_list_spec(
      value,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )

    return(maybe_tib_row(name, fields))
  }

  tib_variant(name)
}

guess_object_list_vector_spec <- function(value, name, ptype, had_empty_lists) {
  if (is_field_scalar(value)) {
    tib_scalar(name, ptype)
  } else {
    mark_empty_list_argument(is_true(had_empty_lists))
    tib_vector(name, ptype)
  }
}

get_required <- function(x, sample_size = 10e3) {
  n <- vec_size(x)
  x <- unname(x)
  if (n > sample_size) {
    n <- sample_size
    x <- vec_slice(x, sample(n, sample_size))
  }

  all_names <- list_unchop(lapply(x, names), ptype = character())
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

  # early exit for performance
  if (!any(sizes == 0)) {
    return(TRUE)
  }

  # check that all elements are `NULL`
  size_0_is_null <- vec_detect_missing(value[sizes == 0])
  all(size_0_is_null)
}

is_field_row <- function(value) {
  should_guess_object_list(value)
}
