test_that("can guess scalar elements", {
  expect_equal(
    spec_guess_object_list(list(list(x = TRUE), list(x = FALSE))),
    spec_df(x = tib_lgl("x"))
  )

  expect_equal(
    spec_guess_object_list(list(list(x = new_datetime(1)), list(x = new_datetime(2)))),
    spec_df(x = tib_scalar("x", new_datetime()))
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    spec_guess_object_list(list(list(x = x_rat), list(x = x_rat))),
    spec_df(x = tib_scalar("x", x_rat))
  )
})

test_that("POSIXlt is converted to POSIXct", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    spec_guess_object_list(list(list(x = x_posixlt), list(x = x_posixlt))),
    spec_df(x = tib_scalar("x", vctrs::new_datetime(tzone = "UTC")))
  )
})

test_that("can guess required for scalars", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = 1.5),
        list()
      )
    ),
    spec_df(x = tib_dbl("x", FALSE))
  )
})

test_that("respect empty_list_unspecified for scalar elements", {
  x <- list(list(x = 1L), list(x = list()))
  expect_equal(
    spec_guess_object_list(x, empty_list_unspecified = FALSE),
    spec_df(x = tib_variant("x"))
  )

  expect_equal(
    spec_guess_object_list(x, empty_list_unspecified = TRUE),
    spec_df(x = tib_int("x"))
  )
})

test_that("can guess vector elements", {
  expect_equal(
    spec_guess_object_list(list(list(x = c(TRUE, FALSE)), list(x = FALSE))),
    spec_df(x = tib_lgl_vec("x"))
  )

  expect_equal(
    spec_guess_object_list(
      list(
        list(x = new_datetime(1)),
        list(x = c(new_datetime(2), new_datetime(3)))
      )
    ),
    spec_df(x = tib_vector("x", new_datetime()))
  )

  skip("Unclear what to guess for empty vector - #78")
  # should this be `tib_int()` or `tib_int_vec()`?
  expect_equal(
    spec_guess_object_list(list(list(x = 1L), list(x = integer()))),
    spec_df(x = tib_int_vec("x"))
  )
})

test_that("can guess required for vector elements", {
  expect_equal(
    spec_guess_object_list(list(list(x = c(TRUE, FALSE)), list())),
    spec_df(x = tib_lgl_vec("x", FALSE))
  )
})

test_that("respect empty_list_unspecified for vector elements", {
  x <- list(list(x = 1:2), list(x = list()))
  expect_equal(
    spec_guess_object_list(x, empty_list_unspecified = FALSE),
    spec_df(x = tib_variant("x"))
  )

  expect_equal(
    spec_guess_object_list(x, empty_list_unspecified = TRUE),
    spec_df(x = tib_int_vec("x"))
  )
})

test_that("can guess tib_variant", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(TRUE, "a")),
        list(x = list(FALSE, "b"))
      )
    ),
    spec_df(x = tib_variant("x"))
  )

  expect_equal(
    spec_guess_object_list(
      list(
        list(x = "a"),
        list(x = 1)
      )
    ),
    spec_df(x = tib_variant("x"))
  )

  # non-vector objects are okay in lists
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = model),
        list(x = model)
      )
    ),
    spec_df(x = tib_variant("x"))
  )
})

test_that("can guess required for tib_variant", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(TRUE, "a")),
        list(y = "a")
      )
    ),
    spec_df(
      x = tib_variant("x", required = FALSE),
      y = tib_chr("y", required = FALSE)
    )
  )
})

test_that("can guess object elements", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(a = 1L, b = "a")),
        list(x = list(a = 2L, b = "b"))
      )
    ),
    spec_df(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )

  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(a = 1L)),
        list(x = list(a = 2:3))
      )
    ),
    spec_df(x = tib_row("x", a = tib_int_vec("a")))
  )

  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(a = 1L)),
        list(x = list(a = "a"))
      )
    ),
    spec_df(x = tib_row("x", a = tib_variant("a")))
  )
})

test_that("respect empty_list_unspecified for object elements", {
  x <- list(list(x = list(y = 1:2)), list(x = list(y = list())))
  expect_equal(
    spec_guess_object_list(x, empty_list_unspecified = FALSE),
    spec_df(x = tib_row("x", y = tib_variant("y")))
  )

  expect_equal(
    spec_guess_object_list(x, empty_list_unspecified = TRUE),
    spec_df(x = tib_row("x", y = tib_int_vec("y")))
  )
})

test_that("can guess tib_df", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(
          x = list(
            list(a = 1L),
            list(a = 2L)
          )
        ),
        list(
          x = list(
            list(a = 1.5)
          )
        )
      )
    ),
    spec_df(x = tib_df("x", a = tib_dbl("a")))
  )
})

test_that("can guess tib_unspecified", {
  expect_equal(spec_guess_object_list(list(list(x = NULL), list(x = NULL))), spec_df(x = tib_unspecified("x")))
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(NULL, NULL)),
        list(x = list(NULL))
      )
    ),
    spec_df(x = tib_unspecified("x"))
  )

  # in a row
  expect_equal(
    spec_guess_object_list(list(list(x = list(a = NULL)), list(x = list(a = NULL)))),
    spec_df(x = tib_row("x", a = tib_unspecified("a")))
  )

  # in a df
  expect_equal(
    spec_guess_object_list(
      list(
        list(
          x = list(
            list(a = NULL),
            list(a = NULL)
          )
        ),
        list(
          x = list(
            list(a = NULL),
            list(a = NULL)
          )
        )
      )
    ),
    spec_df(x = tib_df("x", a = tib_unspecified("a")))
  )
})

test_that("order of fields does not matter", {
  expect_equal(
    spec_guess_object_list(list(list(x = TRUE, y = 1:3), list(z = "a", y = 2L, x = FALSE))),
    spec_df(x = tib_lgl("x"), y = tib_int_vec("y"), z = tib_chr("z", required = FALSE))
  )

  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(a = 1L, b = "a")),
        list(x = list(b = "b", a = 2L))
      )
    ),
    spec_df(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess object_list of length one (#50)", {
  # TODO this should probably rather use `spec_guess()`
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = 1, y = 2)
      )
    ),
    spec_df(
      x = tib_dbl("x"),
      y = tib_dbl("y"),
    )
  )
})
