#' Rectange a nested list into a tidy tibble
#'
#' @param recordlist A nested list.
#' @param col_specs A specification generated with `lcols()` how to turn the
#'   list into a tibble.
#' @param names_to A string specifying the name of the column to create from
#'   the data stored in the column names of data.
#'
#' @return The tibble generated according to the specification.
#' @export
#'
#' @examples
#' recordlist <- list(
#'   list(id = 1, name = "Tyrion Lannister"),
#'   list(id = 2, name = "Victarion Greyjoy")
#' )
#'
#' tibblify(recordlist)
tibblify <- function(recordlist,
                     col_specs = lcols(.default = lcol_guess(zap())),
                     names_to = NULL) {
  tibblify_impl(recordlist, col_specs, keep_spec = TRUE, names_to = names_to)
}


tibblify_impl <- function(recordlist, col_specs, keep_spec, names_to = NULL) {
  default_collector <- col_specs$.default
  collectors <- col_specs$cols

  if (!is_skip_col(default_collector)) {
    fields <- tl_fields(recordlist)
    fields_with_spec <- purrr::map(collectors, list("path", 1))
    fields_without_spec <- setdiff(fields, fields_with_spec)

    new_collectors <- purrr::map(
      fields_without_spec,
      function(field) {
        new_col <- default_collector
        new_col$path <- field
        new_col
      }
    )
    collectors <- c(collectors, set_names(new_collectors, fields_without_spec))
    # auto_names <- attr(collectors, "auto_name")
    # attr(collectors, "auto_name") <- c(attr(collectors, "auto_name"), rep_along(fields_without_spec, TRUE))
  }

  flag_skipped <- purrr::map_lgl(collectors, is_skip_col)
  collectors_non_skip <- purrr::discard(collectors, flag_skipped)

  result_list <- purrr::map(
    collectors_non_skip,
    function(collector) {
      valueslist <- extract_index(recordlist, collector$path, collector$.default)
      apply_collector(collector, valueslist)
    }
  )

  result <- tibble::new_tibble(
    purrr::map(result_list, ~ .x[["values"]]),
    names = names(collectors_non_skip),
    nrow = length(recordlist)
  )

  tibble::validate_tibble(result)

  if (is_true(keep_spec)) {
    collectors[!flag_skipped] <- purrr::map(result_list, "collector")
    col_specs$cols <- collectors

    if (is_guess_col(default_collector)) {
      col_specs$.default <- lcol_skip(zap())
    }

    result <- set_spec(result, col_specs)
  }

  if (!is_null(names_to)) {
    result <- vec_cbind(
      !!names_to := names2(recordlist),
      result
    )
  }

  result
}


#' @importFrom purrr chuck
#' @importFrom purrr pluck
extract_index <- function(recordlist, index, default) {
  tryCatch(
    expr = {
      if (is_zap(default)) {
        purrr::map(recordlist, chuck, !!!index)
      } else {
        purrr::map(recordlist, pluck, !!!index, .default = default)
      }
    },
    error = function(x) {
      abort(paste0("empty or absent element at path ", index))
    }
  )
}

apply_collector <- function(collector, valueslist) {
  UseMethod("apply_collector")
}

#' @export
apply_collector.lcollector_guess <- function(collector, valueslist) {
  result <- guess_col(valueslist, collector$path)
  list(
    values = result$result,
    collector = result$spec
  )
}

#' @export
apply_collector.lcollector_vector <- function(collector, valueslist) {
  list(
    values = simplify_vector(valueslist, ptype = collector$ptype, transform = collector$.parser),
    collector = collector
  )
}

#' @export
apply_collector.lcollector_lst <- function(collector, valueslist) {
  list(
    values = apply_transform(valueslist, transform = collector$.parser),
    collector = collector
  )
}

#' @export
apply_collector.lcollector_lst_of <- function(collector, valueslist) {
  list(
    values = simplify_list_of(valueslist, ptype = collector$ptype, transform = collector$.parser),
    collector = collector
  )
}

#' @export
apply_collector.lcollector_df <- function(collector, valueslist) {
  # `valueslist` is just a list of records so we can just apply `tibblify_impl()`
  list(
    values = tibblify_impl(
      recordlist = valueslist,
      col_specs = collector$.parser,
      keep_spec = FALSE
    ),
    collector = collector
  )
}

#' @export
apply_collector.lcollector_df_lst <- function(collector, valueslist) {
  # basically this would just be
  #
  # map(
  #   valueslist,
  #   ~ tibblify_impl(.x, collector$.parser, keep_spec = FALSE)
  # )
  #
  # but it turned out to be faster to flatten `valueslist`, apply `tibblify_impl`
  # and then split the result
  sizes <- list_sizes(valueslist)
  result <- tibblify_impl(
    recordlist = purrr::flatten(valueslist),
    col_specs = collector$.parser,
    keep_spec = FALSE
  )

  result_split <- split_by_lengths(result, sizes)
  list(
    values = new_list_of(result_split, vec_ptype(result)),
    collector = collector
  )
}

#' Extract all fields of a recordlist
#' @noRd
tl_fields <- function(recordlist) {
  unique(unlist(list_names(recordlist)))
}


list_names <- function(recordlist) {
  purrr::map(recordlist, names)
}
