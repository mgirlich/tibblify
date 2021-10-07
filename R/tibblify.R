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


tibblify_impl <- function(recordlist, col_specs, keep_spec, names_to = NULL, parent_paths = character()) {
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

  resultlist <- vector("list", length(collectors))

  for (i in seq_along(collectors)) {
    collector <- collectors[[i]]
    if (is_skip_col(collector)) {
      next
    }

    tryCatch(
      {
        valueslist <- extract_index(recordlist, collector$path, collector$.default)
      },
      error = function(x) {
        abort(paste0("empty or absent element at path ", paste0(c(parent_paths, collector$path), collapse = "/")))
      }
    )
    if (inherits(collector, "lcollector_df")) {
      resultlist[[i]] <- tibblify_impl(
        recordlist = valueslist,
        col_specs = collector$.parser,
        keep_spec = FALSE,
        parent_paths = c(parent_paths, collector$path)
      )
    } else if (inherits(collector, "lcollector_df_lst")) {
      sizes <- list_sizes(valueslist)
      result <- tibblify_impl(
        recordlist = purrr::flatten(valueslist),
        col_specs = collector$.parser,
        keep_spec = FALSE,
        parent_paths = c(parent_paths, collector$path)
      )

      result_split <- split_by_lengths(result, sizes)
      resultlist[[i]] <- new_list_of(result_split, vec_ptype(result))
    } else if (inherits(collector, "lcollector_guess")) {
      result <- guess_col(valueslist, collector$path)
      resultlist[[i]] <- result$result
      collectors[[i]] <- result$spec
    } else {
      resultlist[[i]] <- simplify_col(valueslist, ptype = collector$ptype, transform = collector$.parser)
    }
  }

  flag_skipped <- purrr::map_lgl(collectors, is_skip_col)

  result <- tibble::new_tibble(
    resultlist[!flag_skipped],
    names = names(collectors)[!flag_skipped],
    nrow = length(recordlist)
  )

  tibble::validate_tibble(result)

  if (is_true(keep_spec)) {
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
  if (is_zap(default)) {
    purrr::map(recordlist, chuck, !!!index)
  } else {
    purrr::map(recordlist, pluck, !!!index, .default = default)
  }
}


#' Extract all fields of a recordlist
#' @noRd
tl_fields <- function(recordlist) {
  unique(unlist(list_names(recordlist)))
}


list_names <- function(recordlist) {
  purrr::map(recordlist, names)
}
