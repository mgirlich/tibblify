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
  expect_error(
    lcol_chr("a", 1),
    class = "vctrs_error_incompatible_type"
  )

  expect_error(
    lcol_chr("a", c("a", "b")),
    class = "vctrs_error_incompatible_size"
  )

  skip("no good way to present error message yet")
  expect_error(
    lcols(
      lcol_df(
        "df_path",
        lcol_chr(list("a", "b"), c("a", "b"))
      )
    ),
    class = "vctrs_error_incompatible_size"
  )
})
