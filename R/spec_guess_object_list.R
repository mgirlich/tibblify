guess_tspec_object_list <- function(x,
                                   ...,
                                   empty_list_unspecified = FALSE,
                                   simplify_list = FALSE,
                                   arg = caller_arg(x),
                                   call = current_call()) {
  check_dots_empty()
  withr::local_options(list(tibblify.used_empty_list_arg = NULL))
  if (is.data.frame(x)) {
    msg <- c(
      "{.arg {arg}} must not be a dataframe.",
      i = "Did you want to use {.fn guess_tspec_df} instead?"
    )
    cli::cli_abort(msg, call = call)
  }

  check_list(x)
  fields <- guess_object_list_spec(
    x,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )

  names_to <- NULL
  if (is_named(x)) {
    names_to <- ".names"
  }

  tspec_df(
    !!!fields,
    .names_to = names_to,
    vector_allows_empty_list = is_true(getOption("tibblify.used_empty_list_arg"))
  )
}

guess_object_list_spec <- function(x,
                                   empty_list_unspecified,
                                   simplify_list) {
  required <- get_required(x)

  # need to remove empty elements for `purrr::transpose()` to work...
  x <- vctrs::list_drop_empty(x)
  x_t <- purrr::transpose(unname(x), names(required))

  fields <- purrr::pmap(
    tibble::tibble(
      value = x_t,
      name = names(required)
    ),
    guess_object_list_field_spec,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
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
    if (is_field_scalar(value)) {
      return(tib_scalar(name, ptype))
    } else {
      mark_empty_list_argument(is_true(ptype_result$had_empty_lists))
      return(tib_vector(name, ptype))
    }
  }

  if (ptype_type == "df") {
    # TODO should this actually be supported?
    # TODO fix error call?
    cli::cli_abort("a list of dataframes is not yet supported")
  }

  if (ptype_type != "list") {
    cli::cli_abort("{.fn tib_type_of} returned an unexpected type", .internal = TRUE)
  }

  # every element is a list at this point
  if (!vec_is_list(ptype)) {
    cli::cli_abort("{.arg ptype} is not a list", .interal = TRUE)
  }

  object <- is_object_list(value)
  object_list <- is_list_of_object_lists(value)

  value_flat <- vec_flatten(value, list(), name_spec = NULL)
  if (object_list && object) {
    if (all(list_sizes(value) == 0)) {
      return(tib_unspecified(name))
    }

    choice <- user_choose_row_or_df(
      name,
      value_flat,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )

    if (choice == "row") {
      object_list <- FALSE
    } else {
      object <- FALSE
    }
  }

  if (object_list) {
    spec <- guess_make_tib_df(
      name,
      values_flat = value_flat,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(spec)
  }

  ptype_result <- get_ptype_common(value_flat, empty_list_unspecified)
  if (object) {
    # it could also be a vector with input form `object`
    if (simplify_list && ptype_result$has_common_ptype && is_field_scalar(value_flat)) {
      # TODO should ask user
      user_choose_row_or_object_vector()
    }

    fields <- guess_object_list_spec(
      value,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list
    )
    return(maybe_tib_row(name, fields))
  }

  if (!ptype_result$has_common_ptype) {
    return(tib_variant(name))
  }

  ptype <- ptype_result$ptype
  if (is_null(ptype) || identical(unname(ptype), list())) {
    return(tib_unspecified(name))
  }

  if (!simplify_list) {
    return(tib_variant(name))
  }

  if (is_field_scalar(value_flat)) {
    if (is_named(value_flat)) {
      return(tib_vector(name, ptype, input_form = "object"))
    } else {
      return(tib_vector(name, ptype, input_form = "scalar_list"))
    }
  }

  tib_variant(name)
}

user_choose_row_or_df <- function(name,
                                  value_flat,
                                  empty_list_unspecified,
                                  simplify_list) {
  if (!rlang::is_interactive()) {
    return("data frame")
  }

  # TODO need full path
  # TODO simplify...
  inner_spec_df <- guess_make_tib_df(
    name,
    values_flat = value_flat,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )
  spec_df <- tspec_df(
    .names_to = inner_spec_df$names_col,
    !!!inner_spec_df$fields
  )
  required <- rep_named(names(spec_df$fields), FALSE)
  spec_df$fields <- update_required_fields(spec_df$fields, required)

  fields <- guess_object_list_spec(
    value,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )
  spec_object <- tspec_row(!!!fields)

  title <- cli::format_message("How should field {.val {name}} be parsed?")
  utils::menu(c("row", "data frame"), title = title)
}

user_choose_row_or_object_vector <- function() {
  if (!rlang::is_interactive()) {
    return("row")
  }

  "row"
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
