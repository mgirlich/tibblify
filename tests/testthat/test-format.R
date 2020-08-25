test_that("format for vectors works", {
  expect_snapshot_output(print(lcol_chr("a")))

  expect_snapshot_output(
    print(lcol_dat("a"))
  )

  expect_snapshot_output(
    print(lcol_dbl("a"))
  )

  expect_snapshot_output(
    print(lcol_dtt("a"))
  )

  expect_snapshot_output(
    print(lcol_guess("a"))
  )

  expect_snapshot_output(
    print(lcol_lgl("a"))
  )

  expect_snapshot_output(
    print(lcol_lst("a"))
  )

  expect_snapshot_output(
    print(lcol_skip("a"))
  )

  expect_snapshot_output(
    print(lcol_int("a"))
  )

  expect_snapshot_output(
    print(lcol_int("a", .default = NA_integer_))
  )

  expect_snapshot_output(
    print(lcol_int("a", .parser = as.integer))
  )

  expect_snapshot_output(
    print(lcol_int("a", .default = NA_integer_, .parser = as.integer))
  )
})

test_that("format for factors work", {
  skip("lcol_fct not yet implemented")
  expect_snapshot_output(
    print(lcol_fct("a"))
  )
})


test_that("format breaks long lines", {
  expect_snapshot_output(
    print(
      lcols(
        just_a_very_long_name = lcol_dbl(
          list("this", "is", "just_a_very_long_name"),
          .parser = ~ and_a_long_function_name(.x)
        )
      )
    )
  )
})


test_that("format for lst_of works", {
  expect_snapshot_output(
    print(lcol_lst_of("a", .ptype = character()))
  )
})

test_that("format for lcol_df works", {
  x <- lcol_df(
    "formats",
    text = lcol_chr("text", .default = NA_character_)
  )

  expect_snapshot_output(print(x))

  x <- lcol_df(
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
  )

  expect_snapshot_output(print(x))
})


test_that("format lcols works", {
  expect_snapshot_output(
    print(
      lcols(
        lcol_int("instance_id"),
        lcol_chr("date_added")
      )
    )
  )

  expect_snapshot_output(
    print(
      lcols(
        lcol_int("instance_id"),
        lcol_chr("date_added"),
        .default = lcol_chr(zap())
      )
    )
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

  expect_snapshot_output(print(col_specs))
})
