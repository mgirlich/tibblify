#' @export
#' @rdname spec_guess
spec_guess_df <- function(x,
                          empty_list_unspecified = FALSE,
                          call = current_call()) {
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
  # TODO add fast path for `list_of` columns?
  if (is.data.frame(col)) {
    fields_spec <- purrr::imap(col, col_to_spec, empty_list_unspecified)
    return(tib_row(name, !!!fields_spec))
  }

  if (col_is_scalar(col)) {
    ptype <- special_ptype_handling(vec_ptype(col))
    if (inherits(ptype, "vctrs_unspecified")) {
      return(tib_unspecified(name))
    }

    return(tib_scalar(name, ptype))
  }

  if (!is.list(col)) {
    cli::cli_abort("Column {name} is not a scalar but also not a list", .internal = TRUE)
  }

  # FIXME From here on this could use `spec_common()`
  # FIXME could use sampling for performance
  # * if `tib_unspecified()` it could use `vctrs::list_drop_empty()` to get
  #   non-empty element

  ptype_common <- get_ptype_common(col, empty_list_unspecified)
  if (!ptype_common$has_common_ptype) {
    return(tib_variant(name))
  }

  ptype <- ptype_common$ptype
  if (is_null(ptype)) {
    return(tib_unspecified(name))
  }

  if (is.data.frame(ptype)) {
    col_required <- df_guess_required(col, colnames(ptype))
    col_flat <- vec_unchop(col, ptype = ptype)

    fields_spec <- purrr::imap(col_flat, col_to_spec, empty_list_unspecified)
    spec <- tib_df(name, !!!fields_spec)
    for (col in names(col_required)) {
      spec$fields[[col]]$required <- col_required[[col]]
    }
    return(spec)
  }

  tib_vector(name, ptype)
}

col_is_scalar <- function(x) {
  # `vec_is()` considers `list()` to be a vector but we don't
  if (vec_is_list(x)) {
    return(FALSE)
  }

  vec_is(x)
}

get_ptype_common <- function(x, empty_list_unspecified) {
  if (empty_list_unspecified) {
    list_sizes_result <- purrr::safely(list_sizes)(x)
    if (inherits(list_sizes_result$error, "vctrs_error_scalar_type")) {
      return(list(has_common_ptype = FALSE))
    }

    empty_flag <- list_sizes_result$result == 0
    empty_list_flag <- purrr::map_lgl(x[empty_flag], ~ identical(.x, list()))
    empty_flag[empty_flag] <- empty_list_flag
    if (any(empty_flag)) {
      x <- x[!empty_flag]
    }
  }

  try_fetch({
    ptype <- vec_ptype_common(!!!x)
    list(has_common_ptype = TRUE, ptype = special_ptype_handling(ptype))
  }, vctrs_error_incompatible_type = function(cnd) {
    list(has_common_ptype = FALSE)
  }, vctrs_error_scalar_type = function(cnd) {
    list(has_common_ptype = FALSE)
  })
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
  cols_list <- purrr::map(df_list, colnames)

  col_required <- rep_named(all_cols, TRUE)
  for (col in all_cols) {
    bad_idx <- purrr::detect_index(cols_list, ~ !col %in% .x)
    col_required[[col]] <- bad_idx == 0
  }

  col_required
}
