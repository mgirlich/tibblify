#' Guess the `tibblify()` Specification
#'
#' @param x A nested list.
#'
#' @return A specification object that can used in `tibblify()`.
#' @export
#'
#' @examples
#' guess_spec(list(x = 1, y = "a"))
#' guess_spec(list(list(x = 1), list(x = 2)))
#'
#' guess_spec(gh_users)
guess_spec <- function(x) {
  UseMethod("guess_spec")
}

#' @export
guess_spec.default <- function(x) {
  type <- get_type(x)
  if (type == "object") x <- list(x)

  fields <- list_fields_to_spec(x)
  if (type == "object") {
    spec_object(!!!fields)
  } else {
    spec_df(!!!fields)
  }
}

list_fields_to_spec <- function(x) {
  n <- vec_size(x)
  if (n > 10e3) {
    x <- vec_slice(x, sample(n, 10e3))
  }
  all_names <- vec_c(!!!lapply(x, names), .ptype = character())
  names_count <- vec_count(all_names, "location")

  empty_loc <- lengths(x) == 0L
  if (any(empty_loc)) {
    required <- rep_along(names_count$count, FALSE)
    x <- x[!empty_loc]
  } else {
    required <- names_count$count == length(x)
  }
  x_t <- purrr::transpose(x, names_count$key)

  purrr::pmap(
    tibble::tibble(
      col = x_t,
      name = names(x_t),
      required
    ),
    list_to_spec
  )
}

list_to_spec <- function(col, name, required) {
  # TODO if all values in a column are NULL inform about this column?
  # or simply return `tib_list()`?
  ptype_safe <- safe_ptype_common2(col)
  if (is_null(ptype_safe$error)) {
    ptype <- ptype_safe$result
    if (is.data.frame(ptype)) {
      browser()
    } else if (vec_is_list(ptype)) {
      if (is_object(col)) {
        browser()
      } else if (is_object_list(col)) {
        fields <- list_fields_to_spec(col)
        if (is_empty(fields)) {
          return(tib_list(name, required))
        }
        return(tib_row(name, !!!fields, .required = required))
      }

      list_of_lists <- all(purrr::map_lgl(col, is.list))
      if (list_of_lists) {
        col_flat <- purrr::flatten(col)
        if (is_object_list(col_flat)) {
          fields <- list_fields_to_spec(col_flat)
          tib_df(name, !!!fields, .required = required)
        } else {
          tib_list(name, required)
        }
      } else {
        tib_list(name, required)
      }
    } else {
      if (vec_is(ptype)) {
        scalar <- all(vctrs::list_sizes(col) <= 1L)
        if (scalar) {
          lcol_to_spec(ptype, name, required)
        } else {
          vec_lcol_to_spec(ptype, name, required)
        }
      } else {
        tib_list(name, required)
      }
    }
  } else {
    tib_list(name, required)
  }
}

#' @export
guess_spec.data.frame <- function(x) {
  browser()
  spec_df(
    !!!purrr::imap(x, col_to_spec)
  )
}

lcol_to_spec <- function(col, name, required = TRUE) {
  UseMethod("lcol_to_spec")
}

#' @export
lcol_to_spec.data.frame <- function(col, name, required = TRUE) {
  browser()
  # tib_row(
  #   name,
  #   !!!purrr::pmpa(
  #     tibble::tibble(col = col, name = colnames(col))
  #   )
  #   !!!purrr::imap(col, col_to_spec)
  # )
}

#' @export
lcol_to_spec.logical <- function(col, name, required) {
  scalar_lcol_to_spec(col, name, required, logical(), tib_lgl)
}

#' @export
lcol_to_spec.integer <- function(col, name, required) {
  scalar_lcol_to_spec(col, name, required, integer(), tib_int)
}

#' @export
lcol_to_spec.double <- function(col, name, required) {
  scalar_lcol_to_spec(col, name, required, double(), tib_dbl)
}

#' @export
lcol_to_spec.character <- function(col, name, required) {
  scalar_lcol_to_spec(col, name, required, character(), tib_chr)
}

scalar_lcol_to_spec <- function(col, name, required, ptype, f) {
  if (vec_is(col, ptype)) {
    f(name, required)
  } else {
    tib_scalar(name, vec_ptype(col), required)
  }
}

#' @export
lcol_to_spec.default <- function(col, name, required = TRUE) {
  tib_scalar(name, vec_ptype(col), required)
}

#' @export
lcol_to_spec.list <- function(col, name, required = TRUE) {
  ptype_safe <- safe_ptype_common2(col)

  if (is_null(ptype_safe$error)) {
    col_flat <- vec_c(!!!col)
    vec_lcol_to_spec(col_flat, name, required)
  } else {
    tib_list(name, required)
  }
}

vec_lcol_to_spec <- function(col, name, required = TRUE) {
  UseMethod("vec_lcol_to_spec")
}

#' @export
vec_lcol_to_spec.data.frame <- function(col, name, required = TRUE) {
  browser()
  tib_df(
    name,
    !!!purrr::imap(col, col_to_spec)
  )
}

#' @export
vec_lcol_to_spec.list <- function(col, name, required = TRUE) {
  browser()
}

#' @export
vec_lcol_to_spec.logical <- function(col, name, required = TRUE) {
  vec_of_lcol_to_spec(col, name, required, logical(), tib_lgl_vec)
}

#' @export
vec_lcol_to_spec.integer <- function(col, name, required = TRUE) {
  vec_of_lcol_to_spec(col, name, required, integer(), tib_int_vec)
}

#' @export
vec_lcol_to_spec.double <- function(col, name, required = TRUE) {
  vec_of_lcol_to_spec(col, name, required, double(), tib_dbl_vec)
}

#' @export
vec_lcol_to_spec.character <- function(col, name, required = TRUE) {
  vec_of_lcol_to_spec(col, name, required, character(), tib_chr_vec)
}

#' @export
vec_lcol_to_spec.default <- function(col, name, required = TRUE) {
  # TODO not sure about this
  tib_scalar(name, vec_ptype(col), required)
}

vec_of_lcol_to_spec <- function(col, name, required = TRUE, ptype, f) {
  if (vec_is(col, ptype)) {
    f(name, required)
  } else {
    tib_scalar(name, vec_ptype(col), required)
  }
}


# data frame --------------------------------------------------------------

#' @export
guess_spec.data.frame <- function(object_list) {
  spec_df(
    !!!purrr::imap(object_list, col_to_spec)
  )
}

col_to_spec <- function(col, name) {
  UseMethod("col_to_spec")
}

#' @export
col_to_spec.data.frame <- function(col, name) {
  tib_row(
    name,
    !!!purrr::imap(col, col_to_spec)
  )
}

#' @export
col_to_spec.logical <- function(col, name) {
  scalar_col_to_spec(col, name, logical(), tib_lgl)
}

#' @export
col_to_spec.integer <- function(col, name) {
  scalar_col_to_spec(col, name, integer(), tib_int)
}

#' @export
col_to_spec.double <- function(col, name) {
  scalar_col_to_spec(col, name, double(), tib_dbl)
}

#' @export
col_to_spec.character <- function(col, name) {
  scalar_col_to_spec(col, name, character(), tib_chr)
}

scalar_col_to_spec <- function(col, name, ptype, f) {
  if (vec_is(col, ptype)) {
    f(name)
  } else {
    tib_scalar(name, vec_ptype(col))
  }
}

#' @export
col_to_spec.default <- function(col, name) {
  tib_scalar(name, vec_ptype(col))
}

#' @export
col_to_spec.list <- function(col, name) {
  ptype_safe <- safe_ptype_common2(col)

  if (is_null(ptype_safe$error)) {
    col_flat <- vec_c(!!!col)
    vec_col_to_spec(col_flat, name)
  } else {
    tib_list(name)
  }
}

safe_ptype_common2 <- function(x) {
  purrr::safely(vec_ptype_common, quiet = TRUE)(!!!x)
}

vec_col_to_spec <- function(col, name) {
  UseMethod("vec_col_to_spec")
}

#' @export
vec_col_to_spec.data.frame <- function(col, name) {
  tib_df(
    name,
    !!!purrr::imap(col, col_to_spec)
  )
}

#' @export
vec_col_to_spec.list <- function(col, name) {
  browser()
}

#' @export
vec_col_to_spec.logical <- function(col, name) {
  vec_of_col_to_spec(col, name, logical(), tib_lgl_vec)
}

#' @export
vec_col_to_spec.integer <- function(col, name) {
  vec_of_col_to_spec(col, name, integer(), tib_int_vec)
}

#' @export
vec_col_to_spec.double <- function(col, name) {
  vec_of_col_to_spec(col, name, double(), tib_dbl_vec)
}

#' @export
vec_col_to_spec.character <- function(col, name) {
  vec_of_col_to_spec(col, name, character(), tib_chr_vec)
}

#' @export
vec_col_to_spec.default <- function(col, name) {
  # TODO not sure about this
  tib_scalar(name, vec_ptype(col))
}

vec_of_col_to_spec <- function(col, name, ptype, f) {
  if (vec_is(col, ptype)) {
    f(name)
  } else {
    tib_scalar(name, vec_ptype(col))
  }
}
