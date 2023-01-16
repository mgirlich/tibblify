test_that("cannot combine different types of spec", {
  df_spec <- tspec_df(a = tib_int("a"))
  row_spec <- tspec_row(a = tib_int("a"))
  obj_spec <- tspec_object(a = tib_int("a"))

  expect_snapshot({
    (expect_error(tspec_combine(df_spec, row_spec)))
    (expect_error(tspec_combine(df_spec, obj_spec)))
    (expect_error(tspec_combine(row_spec, obj_spec)))
  })
})

test_that("cannot combine different keys", {
  expect_snapshot({
    (expect_error(tspec_combine(tspec_df(tib_int("a")), tspec_df(a = tib_int("b")))))
  })
})

test_that("nice error when combining non-specs", {
  df_spec <- tspec_df(a = tib_int("a"))

  expect_snapshot({
    (expect_error(tspec_combine(df_spec, tib_int("a"))))
  })
})

test_that("can combine simple spec with itself", {
  df_spec <- tspec_df(a = tib_int("a"))
  row_spec <- tspec_row(a = tib_int("a"))
  obj_spec <- tspec_object(a = tib_int("a"))

  expect_equal(tspec_combine(df_spec, df_spec), df_spec)
  expect_equal(tspec_combine(row_spec, row_spec), row_spec)
  expect_equal(tspec_combine(obj_spec, obj_spec), obj_spec)
})

test_that("can combine if fields are in different order", {
  spec_ab <- tspec_df(a = tib_int("a"), b = tib_chr("b"))
  spec_ba <- tspec_df(b = tib_chr("b"), a = tib_int("a"))

  expect_equal(tspec_combine(spec_ab, spec_ba), spec_ab)
  expect_equal(tspec_combine(spec_ba, spec_ab), spec_ba)
})

test_that("can combine empty spec", {
  spec_empty <- tspec_df()
  expect_equal(tspec_combine(spec_empty, spec_empty), spec_empty)
})

test_that("can combine required", {
  spec_required <- tspec_df(a = tib_int("a"), b = tib_chr("b"))
  spec_optional <- tspec_df(a = tib_int("a", required = FALSE), b = tib_chr("b"))
  spec_missing <- tspec_df(b = tib_chr("b"))
  spec_empty <- tspec_df()
  spec_all_optional <- spec_optional
  spec_all_optional$fields$b$required <- FALSE

  expect_equal(tspec_combine(spec_required, spec_optional), spec_optional)
  expect_equal(tspec_combine(spec_required, spec_missing), spec_optional)
  expect_equal(tspec_combine(spec_required, spec_empty), spec_all_optional)
})

test_that("can combine type", {
  spec_unspecified <- tspec_df(a = tib_unspecified("a"))
  spec_scalar <- tspec_df(a = tib_int("a"))
  spec_vec <- tspec_df(a = tib_int_vec("a"))
  spec_variant <- tspec_df(a = tib_variant("a"))
  tspec_row <- tspec_df(a = tib_row("a"))
  tspec_df <- tspec_df(a = tib_df("a"))

  expect_equal(tspec_combine(spec_unspecified, spec_unspecified), spec_unspecified)
  expect_equal(tspec_combine(spec_unspecified, spec_scalar), spec_scalar)
  expect_equal(tspec_combine(spec_unspecified, spec_scalar, spec_vec), spec_vec)
  expect_equal(tspec_combine(spec_unspecified, spec_variant), spec_variant)
  expect_equal(tspec_combine(spec_scalar, spec_vec, spec_variant), spec_variant)

  expect_equal(tspec_combine(spec_unspecified, tspec_row), tspec_row)
  expect_equal(tspec_combine(spec_unspecified, tspec_df), tspec_df)

  expect_snapshot({
    (expect_error(tspec_combine(tspec_row, spec_scalar)))
    (expect_error(tspec_combine(tspec_row, spec_vec)))
    (expect_error(tspec_combine(tspec_row, tspec_df)))

    (expect_error(tspec_combine(tspec_df, spec_scalar)))
    (expect_error(tspec_combine(tspec_df, spec_vec)))
  })
})

test_that("can combine ptype", {
  spec_unspecified <- tspec_df(a = tib_unspecified("a"))
  spec_lgl <- tspec_df(a = tib_lgl("a"))
  spec_int <- tspec_df(a = tib_int("a"))
  spec_chr <- tspec_df(a = tib_chr("a"))

  expect_equal(tspec_combine(spec_unspecified, spec_lgl), spec_lgl)
  expect_equal(tspec_combine(spec_unspecified, spec_lgl, spec_int), spec_int)

  expect_snapshot({
    (expect_error(tspec_combine(spec_int, spec_chr)))
  })
})

test_that("can't combine different defaults", {
  spec_no_default <- tspec_df(a = tib_int("a"))
  spec_default1 <- tspec_df(a = tib_int("a", fill = 1))
  spec_default2 <- tspec_df(a = tib_int("a", fill = 2))

  expect_equal(tspec_combine(spec_default1, spec_default1), spec_default1)

  expect_snapshot({
    (expect_error(tspec_combine(spec_no_default, spec_default1)))
    (expect_error(tspec_combine(spec_default1, spec_default2)))
  })

  spec_no_default_vec <- tspec_df(a = tib_int_vec("a"))
  spec_default1_vec <- tspec_df(a = tib_int_vec("a", fill = 1))
  spec_default2_vec <- tspec_df(a = tib_int_vec("a", fill = 2))

  expect_equal(tspec_combine(spec_default1_vec, spec_default1_vec), spec_default1_vec)

  expect_snapshot({
    (expect_error(tspec_combine(spec_no_default_vec, spec_default1_vec)))
    (expect_error(tspec_combine(spec_default1_vec, spec_default2_vec)))
  })
})

test_that("can't combine different transforms", {
  spec_no_f <- tspec_df(a = tib_int("a"))
  spec_f1 <- tspec_df(a = tib_int("a", transform = ~ .x))
  spec_f2 <- tspec_df(a = tib_int("a", transform = ~ .x + 1))

  expect_equal(tspec_combine(spec_f1, spec_f1), spec_f1)

  expect_snapshot({
    (expect_error(tspec_combine(spec_no_f, spec_f1)))
    (expect_error(tspec_combine(spec_f1, spec_f2)))
  })
})

test_that("can't combine different input forms", {
  spec_scalar <- tspec_df(a = tib_int("a"))
  spec_vec <- tspec_df(a = tib_int_vec("a"))
  spec_vec_scalar <- tspec_df(a = tib_int_vec("a", input_form = "scalar_list"))
  spec_vec_object <- tspec_df(a = tib_int_vec("a", input_form = "object"))

  expect_equal(tspec_combine(spec_vec_object, spec_vec_object), spec_vec_object)

  expect_snapshot({
    (expect_error(tspec_combine(spec_vec, spec_vec_scalar)))
    (expect_error(tspec_combine(spec_vec, spec_vec_object)))
    (expect_error(tspec_combine(spec_vec_scalar, spec_vec_object)))

    (expect_error(tspec_combine(spec_scalar, spec_vec_object)))
  })
})

test_that("can't combine different names_to", {
  spec1 <- tspec_df(a = tib_int("a"), .names_to = "name1")
  spec2 <- tspec_df(a = tib_int("a"), .names_to = "name2")

  spec1_df <- tspec_object(a = tib_df("a", .names_to = "name1"))
  spec2_df <- tspec_object(a = tib_df("a", .names_to = "name2"))

  expect_equal(tspec_combine(spec1, spec1), spec1)

  skip_if(paste0(version$major, ".", version$minor) <= '4.0')
  expect_snapshot({
    (expect_error(tspec_combine(spec1, spec2)))
    (expect_error(tspec_combine(spec1_df, spec2_df)))
  })
})
