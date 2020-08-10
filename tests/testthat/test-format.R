test_that("format for vectors works", {
  expect_known_output(
    print(lcol_chr("a")),
    test_path("data", "format_chr.rds")
  )

  expect_known_output(
    format(lcol_dat("a")),
    test_path("data", "format_dat.rds")
  )

  expect_known_output(
    format(lcol_dbl("a")),
    test_path("data", "format_dbl.rds")
  )

  expect_known_output(
    format(lcol_dtt("a")),
    test_path("data", "format_dtt.rds")
  )

  expect_known_output(
    format(lcol_guess("a")),
    test_path("data", "format_guess.rds")
  )

  expect_known_output(
    format(lcol_lgl("a")),
    test_path("data", "format_lgl.rds")
  )

  expect_known_output(
    format(lcol_lst("a")),
    test_path("data", "format_lst.rds")
  )

  expect_known_output(
    format(lcol_skip("a")),
    test_path("data", "format_skip.rds")
  )

  expect_known_output(
    format(lcol_int("a")),
    test_path("data", "format_vector1.rds")
  )

  expect_known_output(
    format(lcol_int("a", .default = NA_integer_)),
    test_path("data", "format_vector2.rds")
  )

  expect_known_output(
    format(lcol_int("a", .parser = as.integer)),
    test_path("data", "format_vector3.rds")
  )

  expect_known_output(
    format(lcol_int("a", .default = NA_integer_, .parser = as.integer)),
    test_path("data", "format_vector4.rds")
  )

  skip("lcol_fct not yet implemented")
  expect_known_output(
    format(lcol_fct("a")),
    test_path("data", "format_fct.rds")
  )
})


test_that("format for lst_flat works", {
  expect_known_output(
    format(lcol_lst_flat("a", .ptype = character())),
    test_path("data", "format_lst_flat.rds")
  )
})

test_that("format for lcol_df works", {
  x <- lcol_df(
    "formats",
    text = lcol_chr("text", .default = NA_character_)
  )

  expect_known_output(x, test_path("data", "format_lcol_df_simple.rds"))

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
  )

  expect_known_output(x, test_path("data", "format_lcol_df_complex.rds"))
})


test_that("format lcols works", {
  expect_known_output(
    format(
      lcols(
        lcol_int("instance_id"),
        lcol_chr("date_added")
      )
    ),
    test_path("data", "format_lcols_simple.rds")
  )

  expect_known_output(
    format(
      lcols(
        lcol_int("instance_id"),
        lcol_chr("date_added"),
        .default = lcol_chr(zap())
      )
    ),
    test_path("data", "format_lcols_default.rds")
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

  expect_known_output(
    print(col_specs),
    test_path("data", "format_lcols_complex.rds")
  )
})
