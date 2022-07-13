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
  spec$fields <- spec_prep(spec$fields, !is.null(spec$names_col))
  path_ptr <- init_tibblify_path()
  call <- current_call()
  try_fetch(
    out <- tibblify_impl(x, spec, path_ptr),
    error = function(cnd) {
      if (inherits(cnd, "tibblify_error")) {
        cnd$call <- call
        cnd_signal(cnd)
      }

      path <- format_path(path_ptr)
      tibblify_abort(
        "Problem while tibblifying {.field {path}}",
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

spec_prep <- function(spec, shift = FALSE) {
  for (i in seq_along(spec)) {
    spec[[i]]$location <- i - 1L + as.integer(shift)
    spec[[i]]$name <- names(spec)[[i]]
  }

  prep_nested_keys(spec)
}

prep_nested_keys <- function(spec, shift = FALSE) {
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
        x$fields <- spec_prep(x$fields, shift = !is.null(x$names_col))
      }

      if (x$type == "scalar") {
        x$na <- vec_init(x$ptype_inner)
      } else if (x$type == "vector") {
        x$na <- vec_init(x$ptype)
      }

      if (x$type == "vector" && !is_null(x$values_to) && !is_null(x$fill)) {
        if (is_null(x$names_to)) {
          fill_list <- set_names(
            list(unname(x$fill)),
            x$values_to
          )
        } else {
          fill_list <- set_names(
            list(names(x$fill), unname(x$fill)),
            c(x$names_to, x$values_to)
          )
        }
        x$fill <- tibble::as_tibble(fill_list)
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
      list(
        key = key,
        type = "sub",
        spec = prep_nested_keys(sub_spec)
      )
    }
  )

  c(
    spec_simple_prepped,
    spec_complex_prepped
  )
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
