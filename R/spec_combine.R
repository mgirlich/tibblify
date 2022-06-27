spec_combine <- function(...) {
  spec_list <- check_spec_combine_dots(...)
  type <- check_spec_combine_type(spec_list)
  fields <- spec_combine_field_list(spec_list, call = current_env())

  if (type == "row") {
    return(spec_row(!!!fields))
  } else if (type == "object") {
    return(spec_object(!!!fields))
  } else if( type == "df") {
    # TODO .names_to
    return(spec_df(!!!fields))
  }

  cli::cli_abort("Unknown spec type", .internal = TRUE)
}

check_spec_combine_dots <- function(..., .call = caller_env()) {
  spec_list <- list2(...)
  bad_idx <- purrr::detect_index(spec_list, ~ !is(.x, "spec_tib"))
  if (bad_idx != 0) {
    cls1 <- class(spec_list[[bad_idx]])[[1]]
    msg <- c(
      "Every element of {.arg ...} must be a tibblify spec.",
      x = "Element {bad_idx} has class {.cls {cls1}}."
    )
    cli::cli_abort(msg, .call = .call)
  }

  spec_list
}

check_spec_combine_type <- function(spec_list, call = caller_env()) {
  types <- purrr::map_chr(spec_list, "type")
  type_locs <- vec_unique_loc(types)

  if (length(type_locs) > 1) {
    type_infos <- loc_name_helper(type_locs, types)
    cli::cli_abort("Can't combine specs {type_infos}", call = call)
  }
  types[[type_locs]]
}

spec_combine_field_list <- function(spec_list, call) {
  fields_list <- purrr::map(spec_list, "fields")
  empty_idx <- lengths(fields_list) == 0
  nms_list <- purrr::map(fields_list, names)
  nms <- vec_unique(vec_flatten(nms_list, character()))
  fields_list_t <- purrr::transpose(fields_list[!empty_idx], nms)

  out <- purrr::map(fields_list_t, tib_combine, call)
  if (any(empty_idx)) {
    for (i in seq_along(out)) {
      out[[i]]$required <- FALSE
    }
  }

  out
}

tib_combine <- function(tib_list, call) {
  required <- tib_combine_required(tib_list)

  # `required` needs to be calculated beforehand
  tib_list <- tib_list[lengths(tib_list) > 0]
  type <- tib_combine_type(tib_list, call)
  key <- tib_combine_key(tib_list, call)

  if (type == "unspecified") {
    return(tib_unspecified(key, required = required))
  }

  if (type %in% c("scalar", "vector")) {
    ptype <- tib_combine_ptype(tib_list, call)
    default <- tib_combine_default(tib_list, type, ptype, call)
    transform <- tib_combine_transform(tib_list, call)

    args <- list(
      key = key,
      ptype = ptype,
      required = required,
      default = default,
      transform = transform
    )

    if (type == "scalar") {
      return(exec(tib_scalar, !!!args))
    } else {
      return(exec(tib_vector, !!!args))
    }
  }

  if (type %in% c("row", "df")) {
    fields <- spec_combine_field_list(tib_list, call)

    if (type == "row") {
      return(tib_row(key, !!!fields, .required = required))
    } else if (type == "df") {
      names_col <- tib_combine_names_col(tib_list, call)
      return(tib_df(key, !!!fields, .required = required, .names_to = names_col))
    }
  }

  cli::cli_abort("Unknown tib type", .internal = TRUE)
}

tib_combine_type <- function(tib_list, call) {
  types <- purrr::map_chr(tib_list, "type")
  locs <- vec_unique_loc(types)
  types <- types[locs]
  unspecified_idx <- types == "unspecified"
  types <- types[!unspecified_idx]
  locs <- locs[!unspecified_idx]

  if (length(types) == 0) {
    return("unspecified")
  }

  if (length(types) == 1) {
    return(types)
  }

  if (all(types %in% c("scalar", "vector"))) {
    return("vector")
  }

  # TODO error message should include path...
  type_infos <- loc_name_helper(locs, types)
  cli::cli_abort("Can't combine tibs {type_infos}", call = call)
}

tib_combine_key <- function(tib_list, call) {
  key_list <- purrr::map(tib_list, "key")
  key_locs <- vec_unique_loc(key_list)

  if (length(key_locs) > 1) {
    # TODO better error message
    keys <- key_list[key_locs]
    cli::cli_abort("Cannot combine tibs of different keys {keys}", call = call, .internal = TRUE)
  }

  key_list[[1]]
}

tib_combine_required <- function(tib_list) {
  null_idx <- purrr::detect_index(tib_list, is_null)
  if (null_idx != 0) {
    return(FALSE)
  }

  # faster alternative to `all(map_lgl())`
  false_idx <- purrr::detect_index(tib_list, ~ !.x[["required"]])
  false_idx == 0
}

tib_combine_ptype <- function(tib_list, call) {
  ptype_list <- lapply(tib_list, `[[`, "ptype")
  # TODO better error message
  rlang::try_fetch(
    vec_ptype_common(!!!ptype_list, .call = call),
    vctrs_error_incompatible_type = function(cnd) {
      x_arg <- cnd$x_arg
      y_arg <- cnd$y_arg
      x_type <- vec_ptype_full(cnd$x)
      y_type <- vec_ptype_full(cnd$y)

      cli::cli_abort(
        "Can't combine tibs with ptype {x_arg} <{x_type}> and {y_arg} <{y_type}>.",
        call = call
      )
    }
  )
}

tib_combine_default <- function(tib_list, type, ptype, call) {
  if (type == "unspecified") {
    return(NULL)
  }

  types <- purrr::map_chr(tib_list, "type")
  unspecified_locs <- which(types == "unspecified")

  default_list <- lapply(tib_list, `[[`, "default_value")

  if (type == "scalar") {
    default_locs <- vec_unique_loc(default_list)
    default_locs <- default_locs[!default_locs %in% unspecified_locs]
    default_list <- default_list[default_locs]

    default_list_cast <- lapply(default_list, vec_cast, ptype)
    default_locs2 <- vec_unique_loc(default_list_cast)
    default_list_cast <- default_list_cast[default_locs2]
    default_locs <- default_locs[default_locs2]

    if (length(default_locs2) > 1) {
      # TODO better error message
      values <- purrr::map_chr(default_list_cast, as_label)
      value_infos <- loc_name_helper(default_locs2, values)
      cli::cli_abort("Can't combine default values {value_infos}", call = call)
    }

    return(vec_cast(default_list_cast[[1]], ptype))
  }

  scalar_idx <- types == "scalar"
  scalar_default <- vec_c(!!!default_list[scalar_idx], .ptype = ptype)
  scalar_na_idx <- vec_equal_na(scalar_default)
  scalar_replace_idx <- scalar_idx[scalar_na_idx]
  default_list[scalar_replace_idx] <- list(NULL)

  default_locs <- vec_unique_loc(default_list)
  default_values <- default_list[default_locs]
  if (length(default_locs) > 1) {
    # TODO better error message
    cli::cli_abort("Cannot combine default values {default_values}", call = call)
  }

  default_value <- default_values[[1]]

  if (is_null(default_value)) {
    default_value
  } else {
    vec_cast(default_value, ptype)
  }
}

tib_combine_transform <- function(tib_list, call) {
  transform_list <- purrr::map(tib_list, "transform")
  transform_locs <- vec_unique_loc(transform_list)

  if (length(transform_locs) > 1) {
    # TODO better error message
    cli::cli_abort("Cannot combine different transforms", call = call)
  }

  transform_list[[transform_locs]]
}

tib_combine_names_col <- function(tib_list, call) {
  names_col <- purrr::map_chr(tib_list, "names_col", .default = NA)
  names_col_locs <- vec_unique_loc(names_col)
  na_locs <- which(vec_equal_na(names_col))

  names_col_locs <- names_col_locs[!names_col_locs %in% na_locs]

  if (is_empty(names_col_locs)) {
    return(NULL)
  }

  if (length(names_col_locs) > 1) {
    # TODO better error message
    cli::cli_abort("Cannot combine different {.arg names_col}", call = call)
  }

  names_col[[names_col_locs]]
}

loc_name_helper <- function(locs, types) {
  types <- types[locs]
  nms <- paste0("`..", locs, "`")
  paste0(nms, " <", types, ">")
}
