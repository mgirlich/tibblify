test_that("can format tib_unspecified()", {
  local_options(cli.num_colors = 1)

  expect_snapshot(tib_unspecified("a") %>% print())
})

test_that("format for scalars works", {
  local_options(cli.num_colors = 1)

  expect_snapshot(tib_chr("a") %>% print())
  # expect_snapshot(tib_dat("a") %>% print())
  expect_snapshot(tib_dbl("a") %>% print())
  # expect_snapshot(tib_dtt("a") %>% print())
  expect_snapshot(tib_int("a") %>% print())
  expect_snapshot(tib_lgl("a") %>% print())

  expect_snapshot(tib_variant("a") %>% print())

  expect_snapshot(tib_int("a", default = NA_integer_) %>% print())
  expect_snapshot(tib_int("a", default = 1) %>% print())

  expect_snapshot(tib_int("a", transform = as.integer) %>% print())
  expect_snapshot(tib_int("a", default = NA_integer_, transform = as.integer) %>% print())

  expect_snapshot(tib_scalar("a", ptype = new_difftime(units = "mins")) %>% print())

  expect_snapshot(
    tib_row(
      "a",
      x = tib_int("x"),
      y = tib_dbl("y", default = NA_real_),
      z = tib_chr("z", default = "abc")
    ) %>% print()
  )
})


test_that("format breaks long lines", {
  local_options(cli.num_colors = 1)
  expect_snapshot(
    tib_row(
      "path",
      a_long_name = tib_dbl("a looooooooooooooooooooong name", default = 1)
    ) %>%
      print(width = 70)
  )

  expect_snapshot(
    tib_row(
      "path",
      a_long_name = tib_dbl("a looooooooooooooooooooong name", default = 1)
    ) %>%
       print(width = 69)
  )
})


test_that("format for tib_vector works", {
  local_options(cli.num_colors = 1)
  expect_snapshot(tib_chr_vec("a") %>% print())
  expect_snapshot(tib_vector("a", ptype = Sys.Date()) %>% print())

  expect_snapshot(
    tib_vector(
      "a",
      ptype = Sys.Date(),
      input_form = "object",
      values_to = "vals",
      names_to = "names"
    ) %>%
      print()
  )

  # multi value default
  expect_snapshot(tib_int_vec("a", default = 1:2) %>% print())
})

test_that("format for tib_row works", {
  local_options(cli.num_colors = 1)
  expect_snapshot(
    tib_row(
      "formats",
      text = tib_chr("text", default = NA_character_)
    ) %>%
      print()
  )

  expect_snapshot(
    tib_row(
      "formats",
      text = tib_chr("text"),
      .required = FALSE
    ) %>%
      print()
  )

  expect_snapshot(
    tib_row(
      "basic_information",
      labels = tib_row(
        "labels",
        name = tib_chr("name"),
        entity_type = tib_chr("entity_type"),
        catno = tib_chr("catno"),
        resource_url = tib_chr("resource_url"),
        id = tib_int("id"),
        entity_type_name = tib_chr("entity_type_name")
      ),
      year = tib_int("year"),
      master_url = tib_chr("master_url", default = NA),
      artists = tib_df(
        "artists",
        join = tib_chr("join"),
        name = tib_chr("name"),
        anv = tib_chr("anv"),
        tracks = tib_chr("tracks"),
        role = tib_chr("role"),
        resource_url = tib_chr("resource_url"),
        id = tib_int("id")
      ),
      id = tib_int("id"),
      thumb = tib_chr("thumb"),
      title = tib_chr("title"),
      formats = tib_df(
        "formats",
        descriptions = tib_chr_vec(
          "descriptions",
          default = NULL
        ),
        text = tib_chr("text", default = NA),
        name = tib_chr("name"),
        qty = tib_chr("qty")
      ),
      cover_image = tib_chr("cover_image"),
      resource_url = tib_chr("resource_url"),
      master_id = tib_int("master_id")
    ) %>%
      print()
  )
})

test_that("format for tib_variant works", {
  expect_snapshot(tib_variant("a"))
  expect_snapshot(tib_variant("a", default = tibble(a = 1:2)))
})

test_that("format for tib_df works", {
  local_options(cli.num_colors = 1)
  expect_snapshot(
    tib_df(
      "formats",
      text = tib_chr("text", default = NA_character_)
    ) %>%
      print()
  )

  expect_snapshot(
    tib_df(
      "formats",
      text = tib_chr("text"),
      .required = FALSE
    ) %>%
      print()
  )

  expect_snapshot(
    tib_df(
      "formats",
      .names_to = "nms",
      text = tib_chr("text")
    ) %>%
      print()
  )
})

test_that("can force to print canonical names", {
  withr::local_options(list(tibblify.print_names = TRUE))

  expect_snapshot(format(
    spec_df(
      a = tib_int("a"),
      b = tib_df(
        "b",
        x = tib_int("x")
      )
    )
  ))
})

test_that("format for empty tib_df works", {
  expect_equal(format(spec_df()), "spec_df()")
  expect_equal(format(spec_row()), "spec_row()")
  expect_equal(format(spec_object()), "spec_object()")
  expect_equal(format(tib_df("x")), "tib_df(\n  \"x\",\n)")
  expect_equal(format(tib_row("x")), "tib_row(\n  \"x\",\n)")
})

test_that("format uses trailing comma", {
  expect_equal(
    format(tib_df("x", a = tib_int("a"))),
    'tib_df(\n  "x",\n  tib_int("a"),\n)'
  )
})
