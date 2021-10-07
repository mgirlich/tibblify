test_known_output <- function(x, width = 80) {
  local_options(cli.num_colors = 1)
  expect_snapshot(print(x, width = width))
}

test_that("format for vectors works", {
  local_options(cli.num_colors = 1)

  expect_snapshot(lcol_chr("a") %>% print())
  expect_snapshot(lcol_dat("a") %>% print())
  expect_snapshot(lcol_dbl("a") %>% print())
  expect_snapshot(lcol_dtt("a") %>% print())
  expect_snapshot(lcol_guess("a") %>% print())
  expect_snapshot(lcol_int("a") %>% print())
  expect_snapshot(lcol_lgl("a") %>% print())

  expect_snapshot(lcol_lst("a") %>% print())

  expect_snapshot(lcol_skip("a") %>% print())

  expect_snapshot(lcol_int("a", .default = NA_integer_) %>% print())
  expect_snapshot(lcol_int("a", .parser = as.integer) %>% print())
  expect_snapshot(lcol_int("a", .default = NA_integer_, .parser = as.integer) %>% print())
  # TODO capture user provided ptype?
  expect_snapshot(lcol_vec("a", ptype = new_difftime(units = "mins")) %>% print())

  skip("lcol_fct not yet implemented")
  expect_snapshot(lcol_fct("a"))
})


test_that("format breaks long lines", {
  local_options(cli.num_colors = 1)
  expect_snapshot(
    lcol_df(
      "path",
      a_long_name = lcol_dbl("a loooooooooooooooooooog name", .default = 1)
    ) %>%
      print(width = 70)
  )

  test_known_output(
    lcol_df(
      "path",
      a_long_name = lcol_dbl("a loooooooooooooooooooog name", .default = 1)
    ) %>%
       print(width = 69)
  )
})


test_that("format for lst_of works", {
  local_options(cli.num_colors = 1)
  expect_snapshot(lcol_lst_of("a", .ptype = character()) %>% print())
})

test_that("format for lcol_df works", {
  local_options(cli.num_colors = 1)
  expect_snapshot(
    lcol_df(
      "formats",
      text = lcol_chr("text", .default = NA_character_)
    ) %>%
      print()
  )

  expect_snapshot(
    lcol_df(
      "basic_information",
      labels = lcol_df(
        "labels",
        name = lcol_chr("name"),
        entity_type = lcol_chr("entity_type"),
        catno = lcol_chr("catno"),
        resource_url = lcol_chr("resource_url"),
        id = lcol_int("id"),
        entity_type_name = lcol_chr("entity_type_name")
      ),
      year = lcol_int("year"),
      master_url = lcol_chr("master_url", .default = NA),
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
          # TODO the `!!!` operator doesn't work in `expect_snapshot()`
          # .parser = ~ vec_c(!!!.x, .ptype = character()),
          .default = NULL
        ),
        text = lcol_chr("text", .default = NA),
        name = lcol_chr("name"),
        qty = lcol_chr("qty")
      ),
      cover_image = lcol_chr("cover_image"),
      resource_url = lcol_chr("resource_url"),
      master_id = lcol_int("master_id")
    ) %>%
      print()
  )
})


test_that("format lcols works", {
  expect_snapshot(
    lcols(
      lcol_int("instance_id"),
      lcol_chr("date_added")
    ) %>%
      print()
  )

  expect_snapshot(
    lcols(
      lcol_int("instance_id"),
      lcol_chr("date_added"),
      .default = lcol_chr(zap())
    ) %>%
      print()
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
      master_url = lcol_chr("master_url", .default = NA),
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
          .parser = ~ vec_c(!!!.x, .ptype = character()),
          .default = NULL
        ),
        text = lcol_chr("text", .default = NA),
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

  expect_snapshot(
    col_specs %>%
      print()
  )
})
