spec_inform_unspecified <- function(spec, action = "inform", call = caller_env()) {
  unspecified_paths <- get_unspecfied_paths(spec)

  lines <- format_unspecified_paths(unspecified_paths)
  if (is_empty(lines)) return(spec)

  msg <- c(
    "The spec contains {length(lines)} unspecified field{?s}:",
    set_names(lines, "*"),
    "\n"
  )

  switch(
    action,
    inform = cli::cli_inform(msg),
    error = cli::cli_abort(msg, call = call)
  )

  invisible(spec)
}

format_unspecified_paths <- function(path_list, path = character()) {
  nms <- names(path_list)
  lines <- character()

  for (i in seq_along(path_list)) {
    nm <- nms[i]
    elt <- path_list[[i]]
    if (is.character(elt)) {
      new_lines <- paste0(path, cli::style_bold(nm))
    } else {
      new_path <- paste0(path, nm, "->")
      new_lines <- format_unspecified_paths(elt, path = new_path)
    }

    lines <- c(lines, new_lines)
  }

  lines
}

get_unspecfied_paths <- function(spec) {
  fields <- spec$fields
  unspecified_paths <- list()

  for (i in seq_along(fields)) {
    field <- fields[[i]]
    nm <- names(fields)[[i]]
    if (field$type == "unspecified") {
      unspecified_paths[[nm]] <- nm
    } else if (field$type %in% c("df", "row")) {
      sub_paths <- get_unspecfied_paths(field)
      unspecified_paths[[nm]] <- sub_paths
    }
  }

  unspecified_paths
}
