test_that("split_by_lengths works", {
  x <- mtcars[1:3, ]

  expect_equal(
    split_by_lengths(x, 3),
    list(x)
  )

  expect_equal(
    split_by_lengths(x, c(1, 1, 1)),
    unname(split(x, 1:3))
  )

  expect_equal(
    split_by_lengths(x, c(1, 0, 2)),
    list(
      x[1, ],
      x[0, ],
      x[2:3, ]
    )
  )
})

test_that("splity_by_lengths input checks work", {
  expect_error(
    split_by_lengths(mtcars, 1)
  )
})

make_list_info <- function(type, ptype, sizes = c(1, 1),
                           absent_or_empty = FALSE,
                           x_flat = NULL, ptype_flat = NULL) {
  list(
    type = type,
    ptype = ptype,
    sizes = sizes,
    absent_or_empty = absent_or_empty,
    x_flat = x_flat,
    ptype_flat = ptype_flat
  )
}

test_that("find_list_type works for unspecified", {
  expect_equal(
    find_list_type(list(NULL, NULL)),
    make_list_info(
      "unspecified",
      NULL,
      c(0, 0),
      absent_or_empty = TRUE
    )
  )
})

test_that("find_list_type works for vectors", {
  expect_equal(
    find_list_type(list("a", "b")),
    make_list_info("vector", character())
  )

  # NULL works
  expect_equal(
    find_list_type(list("a", NULL)),
    make_list_info("vector", character(), c(1, 0), absent_or_empty = TRUE)
  )

  # combine different types
  expect_equal(
    find_list_type(list(1, 2L)),
    make_list_info("vector", numeric())
  )

  # record style objects
  x_rcrd <- as.POSIXlt(Sys.time())
  expect_equal(
    find_list_type(list(x_rcrd, x_rcrd)),
    make_list_info("vector", Sys.time()[0])
  )
})

test_that("find_list_type works for list", {
  # incompatible types
  expect_equal(
    find_list_type(list(1, "a")),
    make_list_info("list", NULL)
  )

  # nested list incompatible types
  expect_equal(
    find_list_type(list(list(1), list("a"))),
    make_list_info(
      "list",
      list(),
      c(1, 1),
      x_flat = NULL,
      ptype_flat = NULL
    )
  )
})

test_that("find_list_type works for list_of", {
  expect_equal(
    find_list_type(list(1, 1:2)),
    make_list_info("list_of", numeric(), c(1, 2))
  )
})

test_that("find_list_type works for nested_list_of", {
  expect_equal(
    find_list_type(list(list(1), list(1:2))),
    make_list_info(
      "nested_list_of",
      list(),
      c(1, 1),
      x_flat = list(1, 1:2),
      ptype_flat = numeric()
    )
  )
})

test_that("find_list_type works for df", {
  expect_equal(
    find_list_type(list(list(a = 1), list(a = 1:2))),
    make_list_info("df", list(), c(1, 1))
  )

  expect_equal(
    find_list_type(list(list(a = 1), list(1:2))),
    make_list_info(
      "nested_list_of",
      list(),
      c(1, 1),
      x_flat = list(a = 1, 1:2),
      ptype_flat = numeric()
    )
  )
})

test_that("find_list_type checks input", {
  expect_error(
    find_list_type(1:3)
  )

  expect_error(
    find_list_type(NULL)
  )

  expect_error(
    find_list_type(list())
  )
})

test_that("find_list_type works for discog", {
  x <- purrr::map(
    discog,
    list("basic_information", "formats")
  )

  expect_equal(find_list_type(x)$type, "list_of_df")
})
