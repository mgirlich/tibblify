test_that("can guess tib_scalar", {
  expect_equal(
    spec_guess_object_list(list(list(x = TRUE), list(x = FALSE))),
    spec_df(x = tib_lgl("x"))
  )

  expect_equal(
    spec_guess_object_list(list(list(x = new_datetime(1)), list(x = new_datetime(2)))),
    spec_df(x = tib_scalar("x", new_datetime()))
  )

  # also for record types
  skip("Correct behaviour is unclear - #77")
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  # vec_ptype(x_posixlt) # -> lt
  # vec_ptype2(x_posixlt, x_posixlt) # -> ct
  expect_equal(
    spec_guess_object_list(list(list(x = x_posixlt), list(x = x_posixlt))),
    spec_df(x = tib_scalar("x", x_posixlt))
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

test_that("can guess tib_vector", {
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

  skip("Correct behaviour is unclear - #78")
  # should this be `tib_int()` or `tib_int_vec()`?
  expect_equal(
    spec_guess_object_list(list(list(x = 1L), list(x = integer()))),
    spec_df(x = tib_int_vec("x"))
  )
})

test_that("can guess required for tib_vector", {
  expect_equal(
    spec_guess_object_list(list(list(x = c(TRUE, FALSE)), list())),
    spec_df(x = tib_lgl_vec("x", FALSE))
  )
})

test_that("can guess tib_list", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(TRUE, "a")),
        list(x = list(FALSE, "b"))
      )
    ),
    spec_df(x = tib_list("x"))
  )

  expect_equal(
    spec_guess_object_list(
      list(
        list(x = "a"),
        list(x = 1)
      )
    ),
    spec_df(x = tib_list("x"))
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
    spec_df(x = tib_list("x"))
  )
})

test_that("can guess required for tib_list", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(TRUE, "a")),
        list(y = "a")
      )
    ),
    spec_df(
      x = tib_list("x", required = FALSE),
      y = tib_chr("y", required = FALSE)
    )
  )
})

test_that("can guess tib_row", {
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
    spec_df(x = tib_row("x", a = tib_list("a")))
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
