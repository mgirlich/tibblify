#' @export
#' @rdname guess_tspec
guess_tspec_df <- function(x,
                          ...,
                          empty_list_unspecified = FALSE,
                          simplify_list = FALSE,
                          inform_unspecified = should_inform_unspecified(),
                          call = rlang::current_call(),
                          arg = rlang::caller_arg(x)) {
  check_dots_empty()
  check_bool(empty_list_unspecified, call = call)
  check_bool(simplify_list, call = call)
  check_bool(inform_unspecified, call = call)

  # FIXME should use global variable?
  withr::local_options(list(tibblify.used_empty_list_arg = NULL))
  if (is.data.frame(x)) {
    fields <- purrr::imap(x, col_to_spec, empty_list_unspecified)
    spec <- tspec_df(
      !!!fields,
      vector_allows_empty_list = is_true(getOption("tibblify.used_empty_list_arg"))
    )
  } else {
    check_list(x, arg = arg)

    if (!is_object_list(x)) {
      msg <- "Not every element of {.arg {arg}} is an object."
      cli::cli_abort(msg, call = call)
    }

    spec <- guess_tspec_object_list(
      x,
      empty_list_unspecified = empty_list_unspecified,
      simplify_list = simplify_list,
      call = call
    )
  }

  if (inform_unspecified) spec_inform_unspecified(spec)
  spec
}

col_to_spec <- function(col, name, empty_list_unspecified) {
  col_type <- tib_type_of(col, name, other = FALSE)

  if (col_type == "df") {
    fields_spec <- purrr::imap(col, col_to_spec, empty_list_unspecified)
    return(tib_row(name, !!!fields_spec))
  }

  if (col_type == "vector") {
    ptype <- tib_ptype(col)
    if (is_unspecified(ptype)) {
      return(tib_unspecified(name))
    }

    return(tib_scalar(name, ptype))
  }

  if (col_type != "list") {
    cli::cli_abort("{.fn tib_type_of} returned an unexpected type", .internal = TRUE)
  }

  # `col` must be a list, so we need to check what its elements are
  list_of_col <- is_list_of(col)
  if (list_of_col) {
    ptype <- col %@% ptype
    ptype_type <- tib_type_of(ptype, name, other = FALSE)
    used_empty_list_argument <- FALSE
  } else {
    # TODO this could use sampling for performance
    ptype_common <- get_ptype_common(col, empty_list_unspecified)
    # no common ptype can be one of two reasons:
    # * it contains non-vector elements
    # * it contains incompatible types
    # in both cases `tib_variant()` is used
    if (!ptype_common$has_common_ptype) {
      return(tib_variant(name))
    }

    ptype <- ptype_common$ptype
    if (is_null(ptype)) {
      # this means that every element is `NULL`
      return(tib_unspecified(name))
    }

    ptype_type <- tib_type_of(ptype, name, other = FALSE)
    used_empty_list_argument <- ptype_common$had_empty_lists
  }

  # At this point each element has type `ptype_type`
  # TODO should this care about names?
  if (ptype_type == "vector") {
    # TODO why?
    mark_empty_list_argument(used_empty_list_argument)
    return(tib_vector(name, ptype))
  }

  if (ptype_type == "df") {
    out <- col_to_spec_df(
      ptype,
      col = col,
      name = name,
      list_of_col = list_of_col,
      empty_list_unspecified = empty_list_unspecified
    )
    return(out)
  }

  if (ptype_type == "list") {
    # TODO this could share code with other guessers
    cli::cli_abort("List columns that only consists of lists are not supported yet.")
  }

  if (col_type != "list") {
    cli::cli_abort("{.fn get_col_type} returned an unexpected type", .internal = TRUE)
  }
}

col_to_spec_df <- function(ptype,
                           col,
                           name,
                           list_of_col,
                           empty_list_unspecified) {
  if (list_of_col) {
    col_required <- TRUE
    has_non_vec_cols <- purrr::detect_index(ptype, ~ !is_vec(.x) || is.data.frame(.x)) > 0
    if (has_non_vec_cols) {
      # non-vector columns need to be inspected further to actually get their
      # specification
      col_flat <- list_unchop(col, ptype = ptype)
    } else {
      col_flat <- ptype
    }
  } else {
    col_required <- df_guess_required(col, colnames(ptype))
    col_flat <- list_unchop(col, ptype = ptype)
  }

  fields_spec <- purrr::imap(col_flat, col_to_spec, empty_list_unspecified)
  for (col in names(col_required)) {
    fields_spec[[col]]$required <- col_required[[col]]
  }

  tib_df(name, !!!fields_spec)
}

df_guess_required <- function(df_list, all_cols) {
  col_required <- rep_named(all_cols, TRUE)
  for (col in all_cols) {
    bad_idx <- purrr::detect_index(
      df_list,
      function(df) !col %in% colnames(df)
    )
    col_required[[col]] <- bad_idx == 0
  }

  col_required
}

globalVariables("had_empty_lists")
