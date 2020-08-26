test_that("lcol_skip checks path", {
  expect_error(
    lcol_skip(c("a", "b")),
    regexp = "path must be a scalar character for"
  )
})
