test_that("scalars work", {
  expect_equal(
    guess_col(list(1L), "a"),
    list(
      result = 1,
      spec = lcol_int("a")
    )
  )

  expect_equal(
    guess_col(list(1, 2L), "a"),
    list(
      result = c(1, 2),
      spec = lcol_dbl("a")
    )
  )

  skip("not yet decided what result should be")
  guess_col(list(1, integer()), "a")

  guess_col(list(1, NULL), "a")
})

test_that("list_of work", {
  expect_equal(
    guess_col(list(1, 1:2), "a"),
    list(
      result = list_of(1, 1:2, .ptype = double()),
      spec = lcol_lst_flat("a", .ptype = double())
    )
  )
})

test_that("lists work", {
  expect_equal(
    guess_col(list(1, "a"), "a"),
    list(
      result = list(1, "a"),
      spec = lcol_lst("a")
    )
  )
})

test_that("recordlist work", {
  recordlist <- list(
    list(a = 1, chr = "a"),
    list(a = 2)
  )

  result <- guess_col(recordlist, "tmp")
  expect_equivalent(
    result$result,
    tibble::tibble(a = 1:2, chr = c("a", NA_character_))
  )

  spec_goal <- lcol_df(
    "tmp",
    a = lcol_dbl("a"),
    chr = lcol_chr("chr", .default = NA_character_),
    .default = zap()
  )

  expect_equal(
    result$spec,
    spec_goal
  )
})
