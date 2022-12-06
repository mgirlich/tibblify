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
    list(
      has_common_ptype = TRUE,
      ptype = special_ptype_handling(ptype),
      had_empty_lists = x %@% had_empty_lists
    )
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
    x %@% had_empty_lists <- TRUE
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

tib_ptype <- function(x) {
  ptype <- vec_ptype(x)
  special_ptype_handling(ptype)
}

is_unspecified <- function(x) {
  inherits(x, "vctrs_unspecified")
}

mark_empty_list_argument <- function(used_empty_list_arg) {
  if (is_true(used_empty_list_arg)) {
    options(tibblify.used_empty_list_arg = TRUE)
  }
}
