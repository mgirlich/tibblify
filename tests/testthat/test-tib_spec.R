test_that("errors on invalid names", {
  expect_snapshot_error(spec_df(x = tib_int("x"), x = tib_int("y")))
})

test_that("can infer name from key", {
  expect_equal(spec_df(tib_int("x")), spec_df(x = tib_int("x")))

  expect_equal(
    spec_df(tib_row("x", tib_int("a"))),
    spec_df(x = tib_row("x", a = tib_int("a")))
  )

  expect_snapshot_error(spec_df(tib_int(1L)))
  expect_snapshot_error(spec_df(tib_int(c("a", "b"))))
  # auto name creates duplicated name
  expect_snapshot_error(spec_df(y = tib_int("x"), tib_int("y")))
})

test_that("errors if `.names_to` column name is not unique", {
  expect_snapshot_error(spec_df(x = tib_int("x"), .names_to = "x"))
})

test_that("errors if element is not a tib collector", {
  expect_snapshot_error(spec_df(x = "a"))
  expect_snapshot_error(spec_df(x = tib_int("x"), y = "a"))
})

test_that("errors on invalid key", {
  expect_snapshot_error(tib_int(1.5))

  expect_snapshot_error(tib_int(list(1.5)))

  expect_snapshot_error(tib_int(list(1:2)))
  expect_snapshot_error(tib_int(list(c("a", "b"))))
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

  expect_snapshot_error(spec_df(spec1, spec1))
})

test_that("empty dots create empty list", {
  expect_equal(spec_df()$fields, list())
  expect_equal(spec_row()$fields, list())
  expect_equal(spec_object()$fields, list())

  expect_equal(tib_df("x")$fields, list())
  expect_equal(tib_row("x")$fields, list())
})

test_that("tib_vector checks arguments", {
  expect_snapshot({
    (expect_error(tib_int_vec("x", input_form = "v")))

    (expect_error(tib_int_vec("x", values_to = 1)))
    (expect_error(tib_int_vec("x", values_to = c("a", "b"))))

    # input_form != "object"
    (expect_error(tib_int_vec("x", values_to = "val", names_to = "name")))
    # values_to = NULL
    (expect_error(tib_int_vec("x", input_form = "object", names_to = "name")))
    # values_to = names_to
    (expect_error(tib_int_vec("x", input_form = "object", values_to = "val", names_to = "val")))

    (expect_error(tib_int_vec("x", input_form = "object", values_to = "val", names_to = 1)))
    (expect_error(tib_int_vec("x", input_form = "object", values_to = "val", names_to = c("a", "b"))))
  })
})
