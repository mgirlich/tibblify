test_that("base vectors work", {
  expect_equal(
    simplify_col(list(), ptype = character()),
    character()
  )

  expect_equal(
    simplify_col(list("a", "b"), ptype = character()),
    c("a", "b")
  )

  # incompatible type
  expect_error(
    simplify_col(list(list("a"), "b"), ptype = character())
  )

  # incompatible ptype
  expect_error(
    simplify_col(list("a", "b"), ptype = integer())
  )

  # incompatible size
  expect_error(
    simplify_col(list(c("a", "b"), "c"), ptype = character())
  )
})

test_that("factors work", {
  skip("lcol_fct not yet implemented")
  x <- c("good", "bad")

  expect_equal(
    simplify_col(as.list(x), ptype = factor(levels = x)),
    factor(x, x)
  )

  expect_equal(
    simplify_col(
      as.list(x),
      ptype = factor(levels = x, ordered = TRUE)
    ),
    factor(x, x, ordered = TRUE)
  )
})

test_that("lists work", {
  expect_equal(
    simplify_col(list("a", "b", "c"), ptype = list()),
    list("a", "b", "c")
  )

  expect_equal(
    simplify_col(list("a", 2, "c"), ptype = list()),
    list("a", 2, "c")
  )
})

test_that("records work", {
  x_rcrd <- rep(as.POSIXlt(Sys.time(), tz = "UTC"), 2)
  expect_equal(
    simplify_col(as.list(x_rcrd), ptype = x_rcrd[[1]]),
    x_rcrd
  )

  expect_error(
    simplify_col(list("2020-08-06 08:39:32 UTC"), ptype = x_rcrd[[1]])
  )
})

test_that("list_of work", {
  x <- list("a", c("b", "c"))
  expect_equal(
    simplify_col(x, ptype = list_of(.ptype = character())),
    new_list_of(x, ptype = character())
  )

  x_rcrd <- as.list(rep(as.POSIXlt(Sys.time(), tz = "UTC"), 2))
  expect_equal(
    simplify_col(x_rcrd, ptype = list_of(.ptype = x_rcrd[[1]])),
    new_list_of(x_rcrd, ptype = vec_ptype(x_rcrd[[1]]))
  )
})

test_that("input is checked", {
  expect_error(
    simplify_col("2020-08-06 08:39:32 UTC", ptype = list())
  )
})
