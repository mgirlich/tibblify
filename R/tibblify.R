#' Rectangle a nested list
#'
#' @param x A nested list.
#' @param spec A specification how to convert `x`. Generated with `tspec_row()`
#'   or `tspec_df()`.
#' @param names_to Deprecated. Use `tspec_df(.names_to)` instead.
#' @param unspecified A string that describes what happens if the specification
#'   contains unspecified fields. Can be one of
#'   * `"error"`: Throw an error.
#'   * `"inform"`: Inform.
#'   * `"drop"`: Do not parse these fields.
#'   * `"list"`: Parse an unspecified field into a list.
#'
#' @return Either a tibble or a list, depending on the specification
#' @seealso Use [`untibblify()`] to undo the result of `tibblify()`.
#' @export
#'
#' @examples
#' x <- list(
#'   list(id = 1, name = "Tyrion Lannister"),
#'   list(id = 2, name = "Victarion Greyjoy")
#' )
#' tibblify(x)
#'
#' # Provide a specification
#' spec <- tspec_df(
#'   id = tib_int("id"),
#'   name = tib_chr("name")
#' )
#' tibblify(x, spec)
#'
#' # Provide a specification for a single object
#' tibblify(x[[1]], tspec_object(spec))
tibblify <- function(x,
                     spec = NULL,
                     names_to = NULL,
                     unspecified = NULL) {
  withr::local_locale(c(LC_COLLATE = "C"))

  if (!is.null(names_to)) {
    lifecycle::deprecate_stop("0.2.0", "tibblify(names_to)")
  }

  if (is_null(spec)) {
    spec <- guess_tspec(x, inform_unspecified = TRUE, call = current_call())
    unspecified <- unspecified %||% "list"
  }

  if (!is_tspec(spec)) {
    friendly_type <- obj_type_friendly(spec)
    msg <- "{.arg spec} must be a tibblify spec, not {friendly_type}."
    cli::cli_abort(msg)
  }

  spec <- tibblify_prepare_unspecified(spec, unspecified, call = current_call())
  spec <- spec_prep(spec)
  spec$rowmajor <- spec$input_form == "rowmajor"

  path <- list(depth = 0, path_elts = list())
  call <- current_call()
  try_fetch(
    out <- .Call(ffi_tibblify, x, spec, path),
    error = function(cnd) {
      if (inherits(cnd, "tibblify_error")) {
        cnd$call <- call
        cnd_signal(cnd)
      }

      path_str <- path_to_string(path)
      tibblify_abort(
        "Problem while tibblifying {.arg {path_str}}",
        parent = cnd,
        call = call
      )
    }
  )

  if (inherits(spec, "tspec_object")) {
    out <- purrr::map2(spec$fields, out, finalize_tspec_object)
  }

  set_spec(out, spec)

  out
}

finalize_tspec_object <- function(field_spec, field) {
  UseMethod("finalize_tspec_object")
}

#' @export
finalize_tspec_object.tib_scalar <- function(field_spec, field) {
  field
}

#' @export
finalize_tspec_object.tib_df <- function(field_spec, field) {
  field[[1]]
}

#' @export
finalize_tspec_object.tib_row <- function(field_spec, field) {
  purrr::map2(field_spec$fields, field, finalize_tspec_object)
}

#' @export
finalize_tspec_object.tib_variant <- function(field_spec, field) {
  field[[1]]
}

#' @export
finalize_tspec_object.tib_vector <- function(field_spec, field) {
  field[[1]]
}

spec_prep <- function(spec) {
  n_cols <- length(spec$fields)
  if (is_null(spec$names_col)) {
    coll_locations <- seq2(1, n_cols) - 1L
    spec$col_names <- names2(spec$fields)
  } else {
    coll_locations <- seq2(1, n_cols)
    n_cols <- n_cols + 1L
    spec$col_names <- c(spec$names_col, names(spec$fields))
  }
  spec$coll_locations <- as.list(coll_locations)
  spec$n_cols <- n_cols

  spec$ptype_dummy <- vctrs::vec_init(list(), n_cols)
  result <- prep_nested_keys2(spec$fields, coll_locations)
  spec$fields <- result$fields
  spec$keys <- result$keys
  spec$coll_locations <- result$coll_locations
  # TODO maybe add `key_match_ind`?

  spec
}

prep_nested_keys2 <- function(spec, coll_locations) {
  remove_first_key <- function(x) {
    x$key <- x$key[-1]
    x
  }

  is_sub <- purrr::map_lgl(spec, ~ length(.x$key) > 1)
  spec_simple <- spec[!is_sub]
  spec_simple_prepped <- purrr::map(
    spec_simple,
    function(x) {
      x$key <- unlist(x$key)

      if (x$type == "row" || x$type == "df") {
        x <- spec_prep(x)
      } else if (x$type == "scalar") {
        x <- prep_tib_scalar(x)
      } else if (x$type == "vector") {
        x <- prep_tib_vector(x)
      }

      x
    }
  )

  spec_complex <- spec[is_sub]

  first_keys <- purrr::map_chr(spec_complex, list("key", 1))
  spec_complex <- purrr::map(spec_complex, remove_first_key)
  spec_split <- vec_split(spec_complex, first_keys)
  spec_complex_prepped <- purrr::map2(
    spec_split$key, spec_split$val,
    function(key, sub_spec) {
      out <- list(
        key = key,
        type = "sub",
        fields = sub_spec
      )

      spec_prep(out)
    }
  )

  spec_out <- c(
    spec_simple_prepped,
    spec_complex_prepped
  )

  coll_locations <- c(
    vec_chop(coll_locations[!is_sub]),
    vec_split(coll_locations[is_sub], first_keys)$val
  )

  keys <- purrr::map_chr(spec_out, list("key", 1))
  key_order <- order(keys)

  list(
    fields = spec_out[key_order],
    coll_locations = coll_locations[key_order],
    keys = keys[key_order]
  )
}

prep_tib <- function(x) {
  if (x$type == "scalar") {
    prep_tib_scalar(x)
  } else if (x$type == "vector") {
    prep_tib_vector(x)
  } else if (x$type %in% c("row", "df")) {

  }
}

prep_tib_scalar <- function(x) {
  x$na <- vctrs::vec_init(x$ptype_inner, 1L)
  x
}

prep_tib_vector <- function(x) {
  if (!is.null(x$names_to) || !is.null(x$values_to)) {
    if (!is.null(x$names_to)) {
      col_names <- c(x$names_to, x$values_to)
      list_of_ptype <- list(character(), x$ptype)
      fill_list <- list(names(x$fill), unname(x$fill))
    } else {
      col_names <- x$values_to
      list_of_ptype <- list(x$ptype)
      fill_list <- list(unname(x$fill))
    }
    if (!is.null(x$fill)) {
      x$fill <- tibble::as_tibble(set_names(fill_list, col_names))
    }
    list_of_ptype <- set_names(list_of_ptype, col_names)
    list_of_ptype <- tibble::as_tibble(list_of_ptype)
  } else {
    col_names <- NULL
    list_of_ptype <- x$ptype
  }

  x["col_names"] <- list(col_names)
  x$list_of_ptype <- list_of_ptype
  x$na <- vec_init(x$ptype)

  x
}

tibblify_prepare_unspecified <- function(spec, unspecified, call) {
  unspecified <- unspecified %||% "error"
  unspecified <- arg_match(unspecified, c("error", "inform", "drop", "list"))

  if (unspecified %in% c("inform", "error")) {
    spec_inform_unspecified(spec, action = unspecified, call = call)
  } else {
    spec_replace_unspecified(spec, unspecified)
  }
}

spec_replace_unspecified <- function(spec, unspecified) {
  unspecified <- arg_match(unspecified, c("drop", "list"))
  fields <- spec$fields

  # need to go backwards over fields because some are removed
  for (i in rev(seq_along(spec$fields))) {
    field <- spec$fields[[i]]
    if (field$type == "unspecified") {
      if (unspecified == "drop") {
        fields[[i]] <- NULL
      } else {
        fields[[i]] <- tib_variant(field$key, required = field$required)
      }
    } else if (field$type %in% c("df", "row")) {
      fields[[i]] <- spec_replace_unspecified(field, unspecified)
    }
  }

  spec$fields <- fields
  spec
}

set_spec <- function(x, spec) {
  attr(x, "tib_spec") <- spec
  x
}

#' Examine the column specification
#'
#' @param x The data frame object to extract from
#'
#' @export
get_spec <- function(x) {
  attr(x, "tib_spec")
}
