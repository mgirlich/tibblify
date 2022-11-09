#' Unnest a recursive data frame
#'
#' @param data A data frame.
#' @param id_col A column that uniquely identifies each observation.
#' @param child_col Column containing the children of an observation. This must
#'   be a list where each element is either `NULL` or a data frame with the same
#'   columns as `data`.
#' @param level_to A string (`"level"` by default) specifying the new column to
#'   store the level of an observation. Use `NULL` if you don't need this
#'   information.
#' @param parent_to A string (`"parent"` by default) specifying the new column
#'   storing the parent id of an observation. Use `NULL` if you don't need this
#'   information.
#' @param ancestors_to A string (`NULL` by default) specifying the new column
#'   storing the ids of its ancestors. Use `NULL` if you don't need this
#'   information.
#'
#' @return A data frame.
#' @export
#'
#' @examples
#' df <- tibble(
#'   id = 1L,
#'   name = "a",
#'   children = list(
#'     tibble(
#'       id = 11:12,
#'       name = c("b", "c"),
#'       children = list(
#'         NULL,
#'         tibble(
#'           id = 121:122,
#'           name = c("d", "e")
#'         )
#'       )
#'     )
#'   )
#' )
#'
#' unnest_tree(
#'   df,
#'   id_col = "id",
#'   child_col = "children",
#'   level_to = "level",
#'   parent_to = "parent",
#'   ancestors_to = "ancestors"
#' )
unnest_tree <- function(data,
                        id_col,
                        child_col,
                        level_to = "level",
                        parent_to = "parent",
                        ancestors_to = NULL) {
  if (!is.data.frame(data)) {
    cli_abort("{.arg data} must be a data frame.")
  }

  id_col <- names(eval_pull(data, enquo(id_col), "id_col"))
  child_col <- names(eval_pull(data, enquo(child_col), "child_col"))
  check_arg_different(child_col, id_col)

  level_to <- check_unnest_level_to(level_to, data)
  parent_to <- check_unnest_parent_to(parent_to, data, level_to)
  ancestors_to <- check_unnest_ancestors_to(ancestors_to, data, level_to, parent_to)

  call <- current_env()

  level_sizes <- list()
  level_parent_ids <- list()
  level_ancestors <- list()
  level_data <- list()
  out_ptype <- vctrs::vec_ptype(data[, setdiff(names(data), child_col)])

  level <- 1L
  parent_ids <- vctrs::vec_init(data[[id_col]])
  ns <- vctrs::vec_size(data)
  cur_ancestors <- vctrs::vec_rep_each(list(NULL), ns)

  while (!is.null(data)) {
    children <- data[[child_col]] %||% list()
    # TODO this could mention the path?
    # -> this would require tracking the current ancestors. Worth it?
    vctrs::vec_check_list(children, arg = child_col)

    data <- data[, setdiff(names(data), child_col)]
    # keep track of the out ptype to error earlier and better error messages (in the future...)
    out_ptype <- vctrs::vec_ptype2(out_ptype, data)
    level_data[[level]] <- data
    # we could also directly repeat the parent ids but it is a bit more efficient
    # to store the parent ids and level sizes in a list and expand + repeat them
    # in the end
    if (!is_null(parent_to)) {
      level_sizes[[level]] <- ns
      level_parent_ids[[level]] <- parent_ids
    }

    if (!is_null(ancestors_to)) {
      if (level > 1L) {
        ancestors_simple <- purrr::map2(cur_ancestors, vctrs::vec_chop(parent_ids), c)
        cur_ancestors <- vctrs::vec_rep_each(ancestors_simple, ns)
      }
      level_ancestors[[level]] <- cur_ancestors
    }

    ns <- vctrs::list_sizes(children)
    if (all(ns == 0)) {
      break
    }

    parent_ids <- data[[id_col]]
    # unclass `list_of` to avoid performance hit
    children <- purrr::map(children, ~ unclass_list_of(.x, child_col, call = call))
    data <- vctrs::list_unchop(children)

    level <- level + 1L
  }

  out <- vctrs::vec_rbind(!!!level_data, .ptype = out_ptype)

  if (!is_null(level_to)) {
    times <- list_sizes(level_data)
    levels <- vctrs::vec_seq_along(level_data)
    out[[level_to]] <- vctrs::vec_rep_each(levels, times)
  }

  if (!is_null(parent_to)) {
    parent_ids <- vctrs::list_unchop(level_parent_ids, ptype = out[[id_col]])
    times <- vctrs::list_unchop(level_sizes, ptype = integer())
    out[[parent_to]] <- vctrs::vec_rep_each(parent_ids, times)
  }

  if (!is_null(ancestors_to)) {
    out[[ancestors_to]] <- vctrs::list_unchop(level_ancestors)
  }

  check_id(out[[id_col]], id_col)
  out
}

unclass_list_of <- function(x, child_col, call = caller_env()) {
  if (is_null(x)) {
    return(NULL)
  }

  if (!inherits(x, "data.frame")) {
    # TODO mention path
    stop_input_type(
      x,
      "a data frame",
      allow_null = TRUE,
      arg = "Each child",
      call = call
    )
  }

  # unclass to avoid slow `[[.tbl_df` and `[[<-.tbl_df`
  x <- unclass(x)
  child_children <- x[[child_col]]
  if (inherits(child_children, "vctrs_list_of")) {
    x[[child_col]] <- unclass(child_children)
  }

  vctrs::new_data_frame(x)
}

check_unnest_level_to <- function(level_to, data, call = caller_env()) {
  if (!is_null(level_to)) {
    level_to <- vctrs::vec_cast(level_to, character(), call = call)
    vctrs::vec_assert(level_to, size = 1L, call = call)
    check_col_new(data, level_to, call = call)
  }

  level_to
}

check_unnest_parent_to <- function(parent_to, data, level_to, call = caller_env()) {
  if (!is_null(parent_to)) {
    parent_to <- vctrs::vec_cast(parent_to, character(), call = call)
    vctrs::vec_assert(parent_to, size = 1L, call = call)
    check_arg_different(parent_to, level_to, call = call)
    check_col_new(data, parent_to, call = call)
  }

  parent_to
}

check_unnest_ancestors_to <- function(ancestors_to,
                                      data,
                                      level_to,
                                      parent_to,
                                      call = caller_env()) {
  if (!is_null(ancestors_to)) {
    ancestors_to <- vctrs::vec_cast(ancestors_to, character(), call = call)
    vctrs::vec_assert(ancestors_to, size = 1L, call = call)
    check_arg_different(ancestors_to, level_to, parent_to, call = call)
    check_col_new(data, ancestors_to, call = call)
  }

  ancestors_to
}

check_col_new <- function(data,
                          col,
                          col_arg = caller_arg(col),
                          data_arg = "data",
                          call = caller_env()) {
  if (col %in% colnames(data)) {
    msg <- "{.arg {col_arg}} must not be a column in {.arg {data_arg}}."
    cli_abort(msg, call = call)
  }
}

#' @importFrom cli cli_abort qty
check_id <- function(x, x_arg, call = caller_env()) {
  if (vctrs::vec_any_missing(x)) {
    incomplete <- vctrs::vec_detect_missing(x)
    incomplete_loc <- which(incomplete)
    n <- length(incomplete_loc)
    msg <- c(
      "Each value of column {.field {x_arg}} must be non-missing.",
      i = "{qty(n)}Element{?s} {incomplete_loc} {qty(n)}{?is/are} missing."
    )
    cli_abort(msg, call = call)
  }

  if (vctrs::vec_duplicate_any(x)) {
    duplicated_flag <- vctrs::vec_duplicate_detect(x)
    duplicated_loc <- which(duplicated_flag)
    msg <- c(
      "Each value of column {.field {x_arg}} must be unique.",
      i = "The elements at locations {duplicated_loc} are duplicated."
    )
    cli_abort(msg, call = call)
  }
}
