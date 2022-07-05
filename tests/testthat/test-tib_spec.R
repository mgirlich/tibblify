
# spec_* ------------------------------------------------------------------

test_that("errors on invalid names", {
  expect_snapshot({
    (expect_error(spec_df(x = tib_int("x"), x = tib_int("y"))))
  })
})

test_that("errors if element is not a tib collector", {
  expect_snapshot({
    (expect_error(spec_df(1)))
    (expect_error(spec_df(x = tib_int("x"), y = "a")))
  })
})

test_that("can infer name from key", {
  expect_equal(spec_df(tib_int("x")), spec_df(x = tib_int("x")))

  expect_equal(
    spec_df(tib_row("x", tib_int("a"))),
    spec_df(x = tib_row("x", a = tib_int("a")))
  )

  expect_snapshot({
    (expect_error(spec_df(tib_int(c("a", "b")))))

    # auto name creates duplicated name
    (expect_error(spec_df(y = tib_int("x"), tib_int("y"))))
  })
})

test_that("can nest specifications", {
  spec1 <- spec_row(
    a = tib_int("a"),
    b = tib_int("b")
  )
  spec2 <- spec_row(
    c = tib_chr("c"),
    d = tib_row("d", x = tib_int("x"))
  )

  expect_equal(
    spec_df(spec1),
    spec_df(!!!spec1$fields)
  )

  expect_equal(
    spec_df(spec1, spec2),
    spec_df(!!!spec1$fields, !!!spec2$fields)
  )

  expect_snapshot((expect_error(spec_df(spec1, spec1))))
})

test_that("errors on invalid `.names_to`", {
  expect_snapshot({
    (expect_error(spec_df(.names_to = NA_character_)))
    (expect_error(spec_df(.names_to = 1)))
  })
})

test_that("errors if `.names_to` column name is not unique", {
  expect_snapshot((expect_error(spec_df(x = tib_int("x"), .names_to = "x"))))
})


# tib_* -------------------------------------------------------------------

test_that("errors on invalid `key`", {
  expect_snapshot({
    (expect_error(tib_int(character())))

    (expect_error(tib_int(NA)))
    (expect_error(tib_int("")))
    (expect_error(tib_int(1L)))

    (expect_error(tib_int(c("x", NA))))
    (expect_error(tib_int(c("x", ""))))
  })
})

test_that("errors on invalid `required`", {
  expect_snapshot({
    (expect_error(tib_int("x", required = logical())))

    (expect_error(tib_int("x", required = NA)))
    (expect_error(tib_int("x", required = 1L)))
    (expect_error(tib_int("x", required = c(TRUE, FALSE))))
  })
})

test_that("errors if dots are not empty", {
  expect_snapshot({
    (expect_error(tib_int("x", TRUE)))
  })
})

test_that("empty dots create empty list", {
  expect_equal(spec_df()$fields, list())
  expect_equal(spec_row()$fields, list())
  expect_equal(spec_object()$fields, list())

  expect_equal(tib_df("x")$fields, list())
  expect_equal(tib_row("x")$fields, list())
})

test_that("tib_scalar checks arguments", {
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  # ptype
  expect_snapshot({
    (expect_error(tib_scalar("x", model)))
  })

  # ptype_inner
  expect_snapshot({
    (expect_error(tib_chr("x", ptype_inner = model)))
  })

  # fill
  expect_snapshot({
    (expect_error(tib_int("x", fill = integer())))
    (expect_error(tib_int("x", fill = 1:2)))
    (expect_error(tib_int("x", fill = "a")))
  })

  # ptype_inner + fill
  expect_snapshot({
    (expect_error(tib_chr("x", fill = 0L, ptype_inner = character())))
  })

  # transform
  expect_snapshot({
    (expect_error(tib_int("x", transform = integer())))
  })
})

test_that("tib_vector checks arguments", {
  # input_form
  expect_snapshot({
    (expect_error(tib_int_vec("x", input_form = "v")))
  })

  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  # ptype
  expect_snapshot({
    (expect_error(tib_vector("x", ptype = model)))
  })

  # ptype_inner
  expect_snapshot({
    (expect_error(tib_chr_vec("x", ptype_inner = model)))
  })

  # values_to
  expect_snapshot({
    (expect_error(tib_int_vec("x", values_to = NA)))
    (expect_error(tib_int_vec("x", values_to = 1)))
    (expect_error(tib_int_vec("x", values_to = c("a", "b"))))
  })

  # names_to
  expect_snapshot({
    # input_form != "object"
    (expect_error(tib_int_vec("x", input_form = "scalar_list", values_to = "val", names_to = "name")))
    # values_to = NULL
    (expect_error(tib_int_vec("x", input_form = "object", names_to = "name")))
    # values_to = names_to
    (expect_error(tib_int_vec("x", input_form = "object", values_to = "val", names_to = "val")))

    (expect_error(tib_int_vec("x", input_form = "object", values_to = "val", names_to = 1)))
    (expect_error(tib_int_vec("x", input_form = "object", values_to = "val", names_to = c("a", "b"))))
  })
})

test_that("tib_chr_date works", {
  expect_equal(
    tib_chr_date("a"),
    tib_scalar_impl(
      "a",
      ptype = vctrs::new_date(),
      ptype_inner = character(),
      format = "%Y-%m-%d",
      transform = ~ as.Date(.x, format = format),
      class = "tib_scalar_chr_date"
    ),
    ignore_function_env = TRUE
  )

  expect_equal(
    tib_chr_date_vec("a"),
    tib_vector_impl(
      "a",
      ptype = vctrs::new_date(),
      ptype_inner = character(),
      format = "%Y-%m-%d",
      transform = ~ as.Date(.x, format = format),
      class = "tib_vector_chr_date"
    ),
    ignore_function_env = TRUE
  )
})

test_that("tib_df() checks arguments", {
  expect_snapshot({
    (expect_error(tib_df("x", .names_to = 1)))
  })
})
