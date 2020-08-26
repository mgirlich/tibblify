test_known_output <- function(x, name, width = 80) {
  expect_known_output(
    print(x, width = width),
    test_path("data", paste0("format_", name, ".txt"))
  )
}

test_that("format for vectors works", {
  test_known_output(
    lcol_chr("a"),
    "chr"
  )

  test_known_output(
    lcol_dat("a"),
    "dat"
  )

  test_known_output(
    lcol_dbl("a"),
    "dbl"
  )

  test_known_output(
    lcol_dtt("a"),
    "dtt"
  )

  test_known_output(
    lcol_guess("a"),
    "guess"
  )

  test_known_output(
    lcol_lgl("a"),
    "lgl"
  )

  test_known_output(
    lcol_lst("a"),
    "lst"
  )

  test_known_output(
    lcol_skip("a"),
    "skip"
  )

  test_known_output(
    lcol_int("a"),
    "vector1"
  )

  test_known_output(
    lcol_int("a", .default = NA_integer_),
    "vector2"
  )

  test_known_output(
    lcol_int("a", .parser = as.integer),
    "vector3"
  )

  test_known_output(
    lcol_int("a", .default = NA_integer_, .parser = as.integer),
    "vector4"
  )

  test_known_output(
    lcol_vec("a", ptype = new_difftime(units = "mins")),
    "lcol_vec"
  )

  skip("lcol_fct not yet implemented")
  test_known_output(
    lcol_fct("a"),
    "fct"
  )
})


test_that("format breaks long lines", {
  test_known_output(
    lcol_df(
      "path",
      a_long_name = lcol_dbl("a loooooooooooooooooooog name", .default = 1)
    ),
    width = 70,
    "does_not_break_short_lines"
  )

  test_known_output(
    lcol_df(
      "path",
      a_long_name = lcol_dbl("a loooooooooooooooooooog name", .default = 1)
    ),
    width = 69,
    "breaks_long_lines"
  )
})


test_that("format for lst_of works", {
  test_known_output(
    lcol_lst_of("a", .ptype = character()),
    "lst_of"
  )
})

test_that("format for lcol_df works", {
  x <- lcol_df(
    "formats",
    text = lcol_chr("text", .default = NA_character_)
  )

  test_known_output(
    x,
    "lcol_df_simple"
  )

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
  )

  test_known_output(
    x,
    "lcol_df_complex"
  )
})


test_that("format lcols works", {
  test_known_output(
    lcols(
      lcol_int("instance_id"),
      lcol_chr("date_added")
    ),
    "lcols_simple"
  )

  test_known_output(
    lcols(
      lcol_int("instance_id"),
      lcol_chr("date_added"),
      .default = lcol_chr(zap())
    ),
    "lcols_default"
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

  test_known_output(
    col_specs,
    "lcols_complex"
  )
})
