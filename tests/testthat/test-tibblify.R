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
    chr_lst_of = lcol_lst_flat("chr_lst", .ptype = character()),
    chr_lst = lcol_lst("chr_lst"),
    lcol_dtt("datetime", .parser = as.POSIXct),
    lcol_skip("skip_it")
  )

  expect_equal(
    tibblify(recordlist, col_specs),
    tibble::tibble(
      chr = purrr::map_chr(recordlist, "chr", .default = NA_character_),
      int = 1:3,
      chr_lst_of = list_of(!!!purrr::map(recordlist, "chr_lst"), .ptype = character()),
      chr_lst = purrr::map(recordlist, "chr_lst"),
      datetime = as.POSIXct(purrr::map_chr(recordlist, "datetime"))
    ),
    ignore_attr = TRUE
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
    ignore_attr = TRUE
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
    ignore_attr = TRUE
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
    ignore_attr = TRUE
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
    ignore_attr = TRUE
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
    ignore_attr = TRUE
  )

  skip("not yet testable")
  expect_equal(
    get_spec(result),
    lcols(lcol_dbl("a")),
    ignore_attr = TRUE
  )
})


test_that("known examples discog", {
  local_edition(2)
  result <- tibblify(discog)
  expect_known_value(
    result,
    test_path("data/discog.rds")
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
        descriptions = lcol_lst_flat(
          "descriptions",
          .ptype = character(0),
          .parser = ~ vec_c(!!!.x, .ptype = character()),
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

  local_edition(3)
  expect_equal(
    result,
    tibblify(discog, col_specs),
    ignore_attr = TRUE
  )
})

test_that("gh_repos works", {
  result <- tibblify(gh_repos)
  expect_snapshot_value(result, style = "json2")
})

test_that("gh_users works", {
  result <- tibblify(gh_users)
  expect_snapshot_value(result, style = "json2")
})

test_that("got_chars works", {
  skip_on_covr()
  result <- tibblify(got_chars)
  expect_snapshot_value(result, style = "json2")
})

test_that("sw_films works", {
  skip_on_covr()
  result <- tibblify(sw_films)
  expect_snapshot_value(result, style = "json2")
})
