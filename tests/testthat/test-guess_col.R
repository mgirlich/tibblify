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
      spec = lcol_lst_of("a", .ptype = double())
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

  expect_error(
    guess_col(list(a = list(a = 1), list(a = 2)), "a"),
    regexp = "all must be named"
  )
})

test_that("recordlist work", {
  recordlist <- list(
    list(a = 1, chr = "a"),
    list(a = 2)
  )

  result <- guess_col(recordlist, "tmp")
  expect_equal(
    result$result,
    tibble::tibble(a = 1:2, chr = c("a", NA_character_)),
    ignore_attr = TRUE
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

test_that("empty cols work", {
  expect_equal(
    guess_col(list(NULL, NULL), "a"),
    list(
      result = list(NULL, NULL),
      spec = lcol_guess("a")
    )
  )
})

test_that("default is found", {
  expect_equal(
    guess_col(list(1, NULL), "a"),
    list(
      result = c(1, NA),
      spec = lcol_dbl("a", .default = NA_real_)
    )
  )
})
