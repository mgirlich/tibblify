#' @export
#' @rdname spec_guess
spec_guess_df <- function(x,
                          ...,
                          empty_list_unspecified = FALSE,
                          call = current_call()) {
  check_dots_empty()
  if (!is.data.frame(x)) {
    if (is.list(x)) {
      msg <- c(
        "{.arg x} must be a {.cls data.frame}. Instead, it is a list.",
        i = "Did you want to use {.fn spec_guess_list()} instead?"
      )
      cli::cli_abort(msg, call = call)
    }

    cls <- class(x)[[1]]
    msg <- "{.arg x} must be a {.cls data.frame}. Instead, it is a {.cls {cls}}."
    cli::cli_abort(msg, call = call)
  }

  spec_df(
    !!!purrr::imap(x, col_to_spec, empty_list_unspecified)
  )
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

  list_of_col <- is_list_of(col)
  if (list_of_col) {
    ptype <- col %@% ptype
    ptype_type <- tib_type_of(ptype, name, other = FALSE)
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
      return(tib_unspecified(name))
    }

    ptype_type <- tib_type_of(ptype, name, other = FALSE)
  }

  # TODO should this care about names?
  if (ptype_type == "vector") {
    return(tib_vector(name, ptype))
  }

  if (ptype_type == "df") {
    if (list_of_col) {
      col_required <- TRUE
      has_non_vec_cols <- purrr::detect_index(ptype, ~ !is_vec(.x) || is.data.frame(.x)) > 0
      if (has_non_vec_cols) {
        col_flat <- vec_unchop(col, ptype = ptype)
      } else {
        col_flat <- ptype
      }
    } else {
      col_required <- df_guess_required(col, colnames(ptype))
      col_flat <- vec_unchop(col, ptype = ptype)
    }

    fields_spec <- purrr::imap(col_flat, col_to_spec, empty_list_unspecified)
    for (col in names(col_required)) {
      fields_spec[[col]]$required <- col_required[[col]]
    }
    return(tib_df(name, !!!fields_spec))
  }

  if (ptype_type == "list") {
    # TODO this could share code with other guessers
    cli::cli_abort("List columns that only consists of lists are not supported yet.")
  }

  if (col_type != "list") {
    cli::cli_abort("{.fn get_col_type} returned an unexpected type", .internal = TRUE)
  }
}

tib_type_of <- function(x, name, other) {
  if (is.data.frame(x)) {
    "df"
  } else if (vec_is_list(x)) {
    "list"
  } else if (vec_is(x)) {
    "vector"
  } else {
    if (!other) {
      msg <- c(
        "Column {name} is not a dataframe, a list or a vector.",
        i = "Instead it has classes {.cls class(x)}."
      )
      cli::cli_abort(msg, .internal = TRUE)
    }
    "other"
  }
}

is_vec <- function(x) {
  # `vec_is()` considers `list()` to be a vector but we don't
  if (vec_is_list(x)) {
    return(FALSE)
  }

  vec_is(x)
}

get_ptype_common <- function(x, empty_list_unspecified) {
  try_fetch({
    if (empty_list_unspecified) {
      x <- drop_empty_lists(x)
    }

    ptype <- vec_ptype_common(!!!x)
    list(has_common_ptype = TRUE, ptype = special_ptype_handling(ptype))
  }, vctrs_error_incompatible_type = function(cnd) {
    list(has_common_ptype = FALSE)
  }, vctrs_error_scalar_type = function(cnd) {
    list(has_common_ptype = FALSE)
  })
}

drop_empty_lists <- function(x) {
  # TODO this could be implement in C for performance
  # for performance reasons don't check for every single element if it is
  # an empty list. Instead, only look at the ones with vec size 0.
  empty_flag <- list_sizes(x) == 0
  empty_list_flag <- purrr::map_lgl(x[empty_flag], ~ identical(.x, list()))
  empty_flag[empty_flag] <- empty_list_flag
  if (any(empty_flag)) {
    x <- x[!empty_flag]
  }

  x
}

special_ptype_handling <- function(ptype) {
  # convert POSIXlt to POSIXct to be in line with vctrs
  # https://github.com/r-lib/vctrs/issues/1576
  if (inherits(ptype, "POSIXlt")) {
    return(vec_cast(ptype, vctrs::new_datetime()))
  }

  ptype
}

df_guess_required <- function(df_list, all_cols) {
  # TODO this could be implement in C for performance
  cols_list <- purrr::map(df_list, colnames)

  col_required <- rep_named(all_cols, TRUE)
  for (col in all_cols) {
    bad_idx <- purrr::detect_index(cols_list, ~ !col %in% .x)
    col_required[[col]] <- bad_idx == 0
  }

  col_required
}
