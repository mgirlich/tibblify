test_that("lcol_skip checks path", {
  expect_snapshot_error(
    lcol_skip(c("a", "b"))
  )
})
