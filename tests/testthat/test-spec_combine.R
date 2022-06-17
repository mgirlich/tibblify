test_that("cannot combine different types of spec", {
  df_spec <- spec_df(a = tib_int("a"))
  row_spec <- spec_row(a = tib_int("a"))
  obj_spec <- spec_object(a = tib_int("a"))

  expect_snapshot({
    (expect_error(spec_combine(df_spec, row_spec)))
    (expect_error(spec_combine(df_spec, obj_spec)))
    (expect_error(spec_combine(row_spec, obj_spec)))
  })
})

test_that("can combine simple spec with itself", {
  df_spec <- spec_df(a = tib_int("a"))
  row_spec <- spec_row(a = tib_int("a"))
  obj_spec <- spec_object(a = tib_int("a"))

  expect_equal(spec_combine(df_spec, df_spec), df_spec)
  expect_equal(spec_combine(row_spec, row_spec), row_spec)
  expect_equal(spec_combine(obj_spec, obj_spec), obj_spec)
})

test_that("can combine if fields are in different order", {
  spec_ab <- spec_df(a = tib_int("a"), b = tib_chr("b"))
  spec_ba <- spec_df(b = tib_chr("b"), a = tib_int("a"))

  expect_equal(spec_combine(spec_ab, spec_ba), spec_ab)
  expect_equal(spec_combine(spec_ba, spec_ab), spec_ba)
})

test_that("can combine empty spec", {
  spec_empty <- spec_df()
  expect_equal(spec_combine(spec_empty, spec_empty), spec_empty)
})

test_that("can combine required", {
  spec_required <- spec_df(a = tib_int("a"), b = tib_chr("b"))
  spec_optional <- spec_df(a = tib_int("a", required = FALSE), b = tib_chr("b"))
  spec_missing <- spec_df(b = tib_chr("b"))
  spec_empty <- spec_df()
  spec_all_optional <- spec_optional
  spec_all_optional$fields$b$required <- FALSE

  expect_equal(spec_combine(spec_required, spec_optional), spec_optional)
  expect_equal(spec_combine(spec_required, spec_missing), spec_optional)
  expect_equal(spec_combine(spec_required, spec_empty), spec_all_optional)
})

test_that("can combine type", {
  spec_unspecified <- spec_df(a = tib_unspecified("a"))
  spec_scalar <- spec_df(a = tib_int("a"))
  spec_vec <- spec_df(a = tib_int_vec("a"))
  spec_row <- spec_df(a = tib_row("a"))
  spec_df <- spec_df(a = tib_df("a"))

  expect_equal(spec_combine(spec_unspecified, spec_unspecified), spec_unspecified)
  expect_equal(spec_combine(spec_unspecified, spec_scalar), spec_scalar)
  expect_equal(spec_combine(spec_unspecified, spec_scalar, spec_vec), spec_vec)

  expect_equal(spec_combine(spec_unspecified, spec_row), spec_row)
  expect_equal(spec_combine(spec_unspecified, spec_df), spec_df)

  expect_snapshot({
    (expect_error(spec_combine(spec_row, spec_scalar)))
    (expect_error(spec_combine(spec_row, spec_vec)))
    (expect_error(spec_combine(spec_row, spec_df)))

    (expect_error(spec_combine(spec_df, spec_scalar)))
    (expect_error(spec_combine(spec_df, spec_vec)))
  })
})

test_that("can combine ptype", {
  spec_unspecified <- spec_df(a = tib_unspecified("a"))
  spec_lgl <- spec_df(a = tib_lgl("a"))
  spec_int <- spec_df(a = tib_int("a"))
  spec_chr <- spec_df(a = tib_chr("a"))

  expect_equal(spec_combine(spec_unspecified, spec_lgl), spec_lgl)
  expect_equal(spec_combine(spec_unspecified, spec_lgl, spec_int), spec_int)

  expect_snapshot({
    (expect_error(spec_combine(spec_int, spec_chr)))
  })
})

test_that("can't combine different defaults", {
  spec_no_default <- spec_df(a = tib_int("a"))
  spec_default1 <- spec_df(a = tib_int("a", default = 1))
  spec_default2 <- spec_df(a = tib_int("a", default = 2))

  expect_equal(spec_combine(spec_default1, spec_default1), spec_default1)

  expect_snapshot({
    (expect_error(spec_combine(spec_no_default, spec_default1)))
    (expect_error(spec_combine(spec_default1, spec_default2)))
  })
})

test_that("can't combine different transforms", {
  spec_no_f <- spec_df(a = tib_int("a"))
  spec_f1 <- spec_df(a = tib_int("a", transform = ~ .x))
  spec_f2 <- spec_df(a = tib_int("a", transform = ~ .x + 1))

  expect_equal(spec_combine(spec_f1, spec_f1), spec_f1)

  expect_snapshot({
    (expect_error(spec_combine(spec_no_f, spec_f1)))
    (expect_error(spec_combine(spec_f1, spec_f2)))
  })
})
