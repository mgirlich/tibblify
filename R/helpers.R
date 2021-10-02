split_by_lengths <- function(x, lengths) {
  if (sum(lengths) != vctrs::vec_size(x)) {
    abort("sum of lengths and the size of x must be the same")
  }

  indices <- vector("list", length(lengths))
  index <- vec_rep_each(seq_along(lengths), lengths)
  indices[lengths > 0] <- split(seq_len(sum(lengths)), index)

  vec_chop(x, indices)
}

find_list_type <- function(x) {
  type <- NA_character_

  if (!is.list(x)) {
    stop("x must be a list.")
  }

  if (vec_size(x) == 0) {
    stop("x must have size > 0.")
  }

  if (all(lengths(x) == 0)) {
    type <- "unspecified"
  }

  ptype <- safe_ptype_common(!!!x)
  sizes <- list_sizes(x)

  x_flat <- NULL
  ptype_flat <- NULL

  if (is.na(type) && is_recordlist(x)) {
    type <- "df"
  }

  if (is.na(type) && is_scalarlist(sizes, ptype)) {
    type <- "vector"
  }

  if (is.na(type) && is_vectorlist(ptype)) {
    type <- "list_of"
  }

  if (is.na(type) && is.null(ptype)) {
    type <- "list"
  }

  if (is.na(type) && is_nested_vectorlist(x)) {
    x_flat <- unlist(x, recursive = FALSE)
    ptype_flat <- safe_ptype_common(!!!x_flat)
    if (!vec_is_list(ptype_flat) && !is.null(ptype_flat)) {
      type <- "nested_list_of"
    } else {
      x_flat <- NULL
      ptype_flat <- NULL
      type <- "list"
    }
  }

  if (is.na(type) && is_list_of_lists(x)) {
    x_flat <- unlist(x, recursive = FALSE)
    if (is_recordlist(x_flat)) {
      type <- "list_of_df"
    } else {
      x_flat <- NULL
      ptype_flat <- NULL
      type <- "list"
    }
  }

  # nocov start
  if (is.na(type)) {
    stop("unknown type")
  }
  # nocov end

  return(
    list(
      type = type,
      ptype = ptype,
      sizes = sizes,
      absent_or_empty = any(sizes == 0),
      x_flat = x_flat,
      ptype_flat = ptype_flat
    )
  )
}
