test_that("errors on invalid names", {
  expect_snapshot_error(spec_df(tib_int("x")))
  expect_snapshot_error(spec_df(x = tib_int("x"), tib_int("y")))
  expect_snapshot_error(spec_df(x = tib_int("x"), x = tib_int("y")))
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
