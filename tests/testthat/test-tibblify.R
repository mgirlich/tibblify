remove_spec <- function(x) {
  attr(x, "spec") <- NULL
  x
}

test_that("works", {
  recordlist <- list(
    list(
      chr = "a",
      int = 1,
      chr_lst = c("a1", "a2"),
      datetime = "2020-08-06 09:02:46 UTC",
      skip_it = 1
    ),
    list(
      chr = "b",
      int = 2,
      chr_lst = "b1",
      datetime = "2021-09-07 11:02:46 UTC"
    ),
    list(
      int = 3,
      chr_lst = character(),
      datetime = "2022-10-08 09:23:46 UTC"
    )
  )

  col_specs <- lcols(
    lcol_chr("chr", .default = NA_character_),
    lcol_int("int"),
    chr_lst_of = lcol_lst_of("chr_lst", .ptype = character()),
    chr_lst = lcol_lst("chr_lst"),
    lcol_dtt("datetime", .parser = ~ as.POSIXct(.x, tz = "UTC")),
    lcol_skip("skip_it")
  )

  expect_equal(
    tibblify(recordlist, col_specs),
    tibble::tibble(
      chr = purrr::map_chr(recordlist, "chr", .default = NA_character_),
      int = 1:3,
      chr_lst_of = list_of(!!!purrr::map(recordlist, "chr_lst"), .ptype = character()),
      chr_lst = purrr::map(recordlist, "chr_lst"),
      datetime = as.POSIXct(purrr::map_chr(recordlist, "datetime"), tz = "UTC")
    ),
    ignore_attr = "spec"
  )

  expect_equal(
    tibblify(list(), col_specs),
    tibble::tibble(
      chr = character(),
      int = integer(),
      chr_lst_of = list_of(.ptype = character()),
      chr_lst = list(),
      datetime = structure(numeric(), class = c("POSIXct", "POSIXt"), tzone = "UTC")
    ),
    ignore_attr = "spec"
  )
})

test_that("missing elements produce error", {
  expect_snapshot_error(
    tibblify(
      list(
        list(a = 1),
        list(b = 1)
      ),
      lcols(lcol_chr("a"))
    )
  )
})

test_that("factors work", {
  skip("lcol_fct not yet implemented")
  x <- list(
    list(a = "good"),
    list(a = "bad"),
    list(a = NA_character_)
  )

  make_spec <- function(levels = NULL,
                        ordered = FALSE,
                        include_na = FALSE) {
    lcols(
      lcol_fct(
        "a",
        levels = levels,
        ordered = ordered,
        include_na = include_na
      )
    )
  }

  make_factor <- function(ordered = FALSE,
                          include_na = FALSE) {
    factor(
      x = c("good", "bad", NA_character_),
      levels = c("good", "bad"),
      ordered = ordered
    )
  }

  expect_equal(
    tibblify(x, make_spec())$a,
    make_factor()
  )

  expect_equal(
    tibblify(x, make_spec(ordered = TRUE))$a,
    make_factor(ordered = TRUE)
  )

  expect_equal(
    tibblify(x, make_spec(include_na = TRUE))$a,
    make_factor(ordered = TRUE)
  )
})

test_that("default works", {
  recordlist <- list(
    list(int = 1, chr = "a"),
    list(int = 2, chr = "b")
  )

  # no default provided
  expect_equal(
    tibblify(
      recordlist,
      col_specs = lcols(
        lcol_int("int")
      )
    ),
    tibble::tibble(int = 1:2),
    ignore_attr = "spec"
  )

  # default: skip
  expect_equal(
    tibblify(
      recordlist,
      lcols(
        lcol_int("int"),
        .default = lcol_skip(zap())
      )
    ),
    tibble::tibble(int = 1:2),
    ignore_attr = "spec"
  )

  # default with transform
  col_specs <- lcols(
    lcol_chr("chr"),
    .default = lcol_chr(
      zap(),
      .parser = as.character
    )
  )

  expect_equal(
    tibblify(
      recordlist,
      col_specs = col_specs
    ),
    tibble::tibble(
      chr = c("a", "b"),
      int = as.character(1:2)
    ),
    ignore_attr = "spec"
  )
})

test_that("df_cols work", {
  recordlist <- list(
    list(
      df = list(
        chr = "a",
        int = 1
      )
    ),
    list(
      df = list(
        chr = "b",
        int = 2
      )
    )
  )

  col_specs <- lcols(
    lcol_df(
      "df",
      lcol_chr("chr", .default = NA_character_),
      lcol_int("int")
    )
  )

  expect_equal(
    tibblify(recordlist, col_specs),
    tibble::tibble(
      df = tibble::tibble(
        chr = c("a", "b"),
        int = 1:2
      )
    ),
    ignore_attr = "spec"
  )

  expect_equal(
    tibblify(list(), col_specs),
    tibble::tibble(
      df = tibble::tibble(
        chr = character(),
        int = integer()
      )
    ),
    ignore_attr = "spec"
  )
})

test_that("df_lst_cols work", {
  recordlist <- list(
    list(
      df = list(
        list(
          chr = "a",
          int = 1
        ),
        list(
          chr = "b",
          int = 2
        )
      )
    ),
    list(
      df = list(
        list(
          chr = "c"
        )
      )
    )
  )

  col_specs <- lcols(
    lcol_df_lst(
      "df",
      lcol_chr("chr"),
      lcol_int("int", .default = NA_integer_),
      .default = NULL
    )
  )

  expect_equal(
    tibblify(recordlist, col_specs),
    tibble::tibble(
      df = list_of(
        tibble::tibble(
          chr = c("a", "b"),
          int = 1:2
        ),
        tibble::tibble(
          chr = "c",
          int = NA_integer_
        )
      )
    ),
    ignore_attr = "spec"
  )

  expect_equal(
    tibblify(list(), col_specs),
    tibble::tibble(
      df = list_of(.ptype =
        tibble::tibble(
          chr = character(),
          int = integer()
        )
      )
    ),
    ignore_attr = "spec"
  )
})


test_that("guess_col works", {
  recordlist <- list(
    list(a = 1),
    list(a = 2)
  )

  result <- tibblify(
    recordlist,
    col_specs = lcols(.default = lcol_guess(zap()))
  )

  expect_equal(
    result,
    tibble::tibble(a = 1:2),
    ignore_attr = "spec"
  )

  expect_equal(
    get_spec(result),
    lcols(lcol_dbl("a")),
    ignore_attr = "spec"
  )
})


test_that("guess_col works with default", {
  recordlist <- list(
    list(a = 1),
    list(a = 2)
  )

  col_specs <- lcols(a = lcol_guess("a", .default = NULL))

  result <- tibblify(recordlist, col_specs = col_specs)

  expect_equal(
    result,
    tibble::tibble(a = 1:2),
    ignore_attr = "spec"
  )

  expect_equal(
    get_spec(result),
    lcols(lcol_dbl("a")),
    ignore_attr = "spec"
  )

  # Need expect_equal() because list() appears to be equivalent to unspecified()
  expect_equal(
    tibblify_impl(list(), col_specs, keep_spec = FALSE),
    tibble::tibble(a = vctrs::unspecified()),
    ignore_attr = "spec"
  )
})


test_that("lcol_vec works", {
  x_rcrd <- as.POSIXlt(Sys.time(), tz = "UTC")
  recordlist <- list(
    list(a = x_rcrd),
    list(a = x_rcrd + 1)
  )

  spec <- lcols(
    lcol_vec("a", ptype = x_rcrd)
  )

  expect_equal(
    tibblify(recordlist, spec),
    tibble::tibble(a = vec_c(!!!purrr::map(recordlist, "a"), .ptype = x_rcrd)),
    ignore_attr = "spec"
  )

  now <- Sys.time()
  past <- now - c(100, 200)

  recordlist <- list(
    list(timediff = now - past[1]),
    list(timediff = now - past[2])
  )

  spec <- lcols(
    lcol_vec("timediff", ptype = recordlist[[1]]$timediff)
  )

  expect_equal(
    tibblify(recordlist, spec),
    tibble::tibble(timediff = vec_c(!!!purrr::map(recordlist, "timediff"))),
    ignore_attr = "spec"
  )
})

test_that("records work", {
  x_rcrd <- rep(as.POSIXlt(Sys.time(), tz = "UTC"), 2)
  expect_equal(
    simplify_col(as.list(x_rcrd), ptype = x_rcrd[[1]]),
    x_rcrd
  )

  expect_error(
    simplify_col(list("2020-08-06 08:39:32 UTC"), ptype = x_rcrd[[1]])
  )
})

test_that("`names_to` works", {
  recordlist <- list(
    a = list(x = 1),
    b = list(x = 2)
  )

  # TODO should `x` be named or not?
  expect_equal(
    tibblify(recordlist, names_to = "name"),
    tibble::tibble(name = c("a", "b"), x = c(a = 1, b = 2)),
    ignore_attr = "spec"
  )
})

test_that("known examples discog", {
  result <- tibblify(discog[1:2])
  expect_snapshot_value(
    result %>% remove_spec(),
    style = "json2",
    ignore_function_env = TRUE,
    ignore_formula_env = TRUE
  )

  col_specs <- lcols(
    lcol_int("instance_id"),
    lcol_chr("date_added"),
    lcol_df(
      "basic_information",
      labels = lcol_df_lst(
        "labels",
        name = lcol_chr("name"),
        entity_type = lcol_chr("entity_type"),
        catno = lcol_chr("catno"),
        resource_url = lcol_chr("resource_url"),
        id = lcol_int("id"),
        entity_type_name = lcol_chr("entity_type_name")
      ),
      year = lcol_int("year"),
      master_url = lcol_chr("master_url", .default = NA_character_),
      artists = lcol_df_lst(
        "artists",
        join = lcol_chr("join"),
        name = lcol_chr("name"),
        anv = lcol_chr("anv"),
        tracks = lcol_chr("tracks"),
        role = lcol_chr("role"),
        resource_url = lcol_chr("resource_url"),
        id = lcol_int("id")
      ),
      id = lcol_int("id"),
      thumb = lcol_chr("thumb"),
      title = lcol_chr("title"),
      formats = lcol_df_lst(
        "formats",
        descriptions = lcol_lst_of(
          "descriptions",
          .ptype = character(0),
          .parser = ~ vctrs::vec_c(!!!.x, .ptype = character()),
          .default = NULL
        ),
        text = lcol_chr("text", .default = NA_character_),
        name = lcol_chr("name"),
        qty = lcol_chr("qty")
      ),
      cover_image = lcol_chr("cover_image"),
      resource_url = lcol_chr("resource_url"),
      master_id = lcol_int("master_id")
    ),
    lcol_int("id"),
    lcol_int("rating"),
  )

  expect_equal(
    result,
    tibblify(discog[1:2], col_specs),
    ignore_function_env = TRUE,
    ignore_formula_env = TRUE
  )
})

test_that("gh_repos works", {
  skip_on_cran()
  expect_snapshot_value(
    tibblify(gh_repos[1:2]) %>% remove_spec(),
    style = "json2",
    ignore_function_env = TRUE,
    ignore_formula_env = TRUE
  )
})

test_that("gh_users works", {
  skip_on_cran()
  expect_snapshot_value(
    tibblify(gh_users[1:2]) %>% remove_spec(),
    style = "json2",
    ignore_function_env = TRUE,
    ignore_formula_env = TRUE
  )
})

test_that("got_chars works", {
  skip_on_covr()
  skip_on_cran()
  expect_snapshot_value(
    tibblify(got_chars[1:2]) %>% remove_spec(),
    style = "json2",
    ignore_function_env = TRUE,
    ignore_formula_env = TRUE
  )
})

test_that("sw_films works", {
  skip_on_covr()
  skip_on_cran()
  expect_snapshot_value(
    tibblify(sw_films[1:2]) %>% remove_spec(),
    style = "json2",
    ignore_function_env = TRUE,
    ignore_formula_env = TRUE
  )
})
