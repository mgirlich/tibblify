guess_col <- function(x, path) {
  list_info <- find_list_type(x)
  type <- list_info$type
  ptype <- list_info$ptype
  sizes <- list_info$sizes
  x_flat <- list_info$x_flat
  ptype_flat <- list_info$ptype_flat
  absent_or_empty <- list_info$absent_or_empty

  if (absent_or_empty) {
    .default <- NULL
  } else {
    .default <- zap()
  }

  if (type == "unspecified") {
    return(
      list(
        result = vctrs::unspecified(vctrs::vec_size(x)),
        spec = lcol_guess(path, .default = NULL)
      )
    )
  }

  if (type == "df") {
    result <- tibblify_impl(
      x,
      lcols(.default = lcol_guess(zap(), .default = NULL)),
      keep_spec = TRUE
    )
    spec <- get_spec(result)
    result <- set_spec(result, NULL)

    return(
      list(
        result = result,
        spec = lcol_df(
          path = path,
          !!!spec$cols,
          .default = .default
        )
      )
    )
  }

  if (type == "vector") {
    result <- vec_c(!!!x, .ptype = ptype)

    if (any(sizes == 0)) {
      i <- cumsum(sizes)
      i[sizes == 0] <- NA
      result <- vec_slice(result, i)

      .default <- result[which.max(sizes == 0)]
    } else {
      .default <- zap()
    }

    type <- vec_ptype_abbr(ptype)

    known_types <- c("lgl", "int", "dbl", "chr", "dat", "dtt")
    if (type %in% known_types) {
      spec <- lcollector(
        path,
        type = vec_ptype_abbr(ptype),
        ptype = ptype,
        .default = .default,
        .parser = NULL,
        .parser_expr = NULL
      )
    } else {
      spec <- lcol_vec(
        path,
        ptype = ptype,
        .default = .default
      )
    }
    # attr(spec, "auto_name") <- TRUE

    return(list(result = result, spec = spec))
  }

  if (type == "list_of") {
    result <- simplify_col(x, ptype = list_of(.ptype = ptype))

    spec <- lcol_lst_of(
      path = path,
      .ptype = ptype,
      .default = .default
    )
    # attr(spec, "auto_name") <- TRUE

    return(list(result = result, spec = spec))
  }

  if (type == "nested_list_of") {
    result <- simplify_col(
      x,
      ptype = list_of(.ptype = ptype_flat),
      ~ vec_c(!!!.x, .ptype = ptype_flat)
    )

    spec <- lcol_lst_of(
      path = path,
      .ptype = ptype_flat,
      .parser = ~ vctrs::vec_c(!!!.x, .ptype = character()),
      .default = NULL
    )

    return(list(result = result, spec = spec))
  }

  if (type == "list_of_df") {
    result_unlisted <- tibblify_impl(
      x_flat,
      lcols(.default = lcol_guess(zap(), .default = NULL)),
      keep_spec = TRUE
    )
    spec_unlisted <- get_spec(result_unlisted)
    result_unlisted <- set_spec(result_unlisted, NULL)

    result <- split_by_lengths(result_unlisted, lengths(x))
    result <- new_list_of(result, ptype = vec_ptype(result_unlisted))

    spec <- lcol_df_lst(
      path,
      !!!spec_unlisted$cols,
      .default = .default
    )

    return(list(result = result, spec = spec))
  }

  if (type == "list") {
    result <- x

    spec <- lcol_lst(path, .default = .default)
    # attr(spec, "auto_name") <- TRUE

    return(list(result = result, spec = spec))
  }

  # nocov start
  stop("something unexpected happened")
  # nocov end
}

#' @noRd
#' @examples
#' x <- list(
#'   list(a = 1),
#'   list(a = 2)
#' )
#'
#' # should this be a recordlist?
#' x <- list(
#'   list(a = 1),
#'   list()
#' )
#'
#' # should this be a recordlist?
#' x <- list(
#'   list(a = 1),
#'   NULL
#' )
is_recordlist <- function(x) {
  # * all elements are a list or `NULL`
  # * all elements are fully named?
  # * empty list element?

  # .Call(C_is_recordlist, x)
  # jsonlite:::is.recordlist(x)

  if (!(is_unnamedlist(x) && length(x))) {
    return(FALSE)
  }
  at_least_one_object <- FALSE
  for (i in x) {
    if (!(is_namedlist(i) || is.null(i))) {
      return(FALSE)
    }
    if (!at_least_one_object && is_namedlist(i)) {
      at_least_one_object <- TRUE
    }
  }
  return(at_least_one_object)
}

is_unnamedlist <- function(x) {
  isTRUE(is.list(x) && is.null(names(x)))
}

is_namedlist <- function(x) {
  isTRUE(is.list(x) && !is.null(names(x)))
}

is_scalarlist <- function(sizes, ptype) {
  # what about size 0 elements?
  # * integer()
  # * NULL

  !is.null(ptype) &&
    !vec_is_list(ptype) &&
    all(sizes <= 1)
  # or
  # all(sizes == 1)

  # ~~~~~~~~~~
  # jsonlite definition
  # ~~~~~~~~~~
  # if (!is.list(x))
  #   return(FALSE)
  # for (i in x) {
  #   if (!is.atomic(i) || length(i) > 1)
  #     return(FALSE)
  # }
  # return(TRUE)
}

is_vectorlist <- function(ptype) {
  !is.null(ptype) &&
    !vec_is_list(ptype)

  # is.atomic returns TRUE for `NULL`
  # all(vapply(x, function(elt) is.atomic(elt), logical(1)))
}

is_nested_vectorlist <- function(x) {
  ptype_list <- purrr::map(x, ~ vec_ptype_common(!!!.x))
  # all(purrr::map_lgl(ptype_list, is_vectorlist))
  all(vapply(ptype_list, function(elt) is.null(elt) || is_vectorlist(elt), logical(1)))

  # all(vapply(x, function(elt) is.null(elt) || is_vectorlist(elt), logical(1)))
}

safe_ptype_common <- function(...) {
  tryCatch(vec_ptype_common(..., .ptype = NULL), error = function(e) NULL)
}

is_list_of_lists <- function(x) {
  list_flag <- vapply(x, function(elt) {
    is_list(elt) || rlang::is_null(elt)
  }, logical(1))
  all(list_flag)
}
