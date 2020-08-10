test_that("lcols checks input", {
  expect_error(lcols())

  expect_error(
    lcols(lcol_chr(1))
  )

  expect_error(
    lcols(
      lcol_chr("a"),
      lcol_chr("a")
    ),
    class = "vctrs_error_names_must_be_unique"
  )

  expect_error(
    lcols("a")
  )

  expect_error(
    lcols(lcol_chr("a"), .default = "a")
  )
})

test_that("lcollector checks default value", {
  expect_error(lcol_chr("a", 1))

  expect_error(lcol_chr("a", c("a", "b")))
})
