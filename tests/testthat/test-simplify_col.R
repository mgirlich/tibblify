test_that("base vectors work", {
  expect_equal(
    simplify_vector(list(), ptype = character()),
    character()
  )

  expect_equal(
    simplify_vector(list("a", "b"), ptype = character()),
    c("a", "b")
  )

  # incompatible type
  expect_snapshot_error(
    simplify_vector(list(list("a"), "b"), ptype = character())
  )

  # incompatible ptype
  expect_snapshot_error(
    simplify_vector(list("a", "b"), ptype = integer())
  )

  # incompatible size
  expect_snapshot_error(
    simplify_vector(list(c("a", "b"), "c"), ptype = character())
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

test_that("records work", {
  x_rcrd <- rep(as.POSIXlt(Sys.time(), tz = "UTC"), 2)
  expect_equal(
    simplify_vector(as.list(x_rcrd), ptype = x_rcrd[[1]]),
    x_rcrd
  )

  expect_snapshot_error(
    simplify_vector(list("2020-08-06 08:39:32 UTC"), ptype = x_rcrd[[1]])
  )
})

test_that("list_of work", {
  x <- list("a", c("b", "c"))
  expect_equal(
    simplify_list_of(x, ptype = character()),
    new_list_of(x, ptype = character())
  )

  x_rcrd <- as.list(rep(as.POSIXlt(Sys.time(), tz = "UTC"), 2))
  expect_equal(
    simplify_list_of(x_rcrd, ptype = x_rcrd[[1]]),
    new_list_of(x_rcrd, ptype = vec_ptype(x_rcrd[[1]]))
  )

  expect_snapshot_error(
    simplify_list_of(list("a", 1L), ptype = character())
  )
})

test_that("input is checked", {
  expect_error(
    simplify_col("2020-08-06 08:39:32 UTC", ptype = list())
  )
})
