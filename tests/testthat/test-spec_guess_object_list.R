test_that("can guess tib_scalar in an object_list", {
  expect_equal(
    spec_guess_object_list(list(list(x = TRUE), list(x = FALSE))),
    spec_df(x = tib_lgl("x"))
  )
  expect_equal(
    spec_guess_object_list(list(list(x = new_datetime(1)), list(x = new_datetime(2)))),
    spec_df(x = tib_scalar("x", new_datetime()))
  )
})

test_that("can guess tib_vector in an object_list", {
  expect_equal(
    spec_guess_object_list(list(list(x = c(TRUE, FALSE)), list(x = FALSE))),
    spec_df(x = tib_lgl_vec("x"))
  )
  expect_equal(
    spec_guess_object_list(list(list(x = "a"), list(x = c("b", "c")))),
    spec_df(x = tib_chr_vec("x"))
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
})

test_that("can guess tib_list in an object_list", {
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
})

test_that("can guess tib_row in an object_list", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = list(a = 1L, b = "a")),
        list(x = list(a = 2L, b = "b"))
      )
    ),
    spec_df(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess tib_df in an object_list", {
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

test_that("can guess required in an object_list", {
  expect_equal(
    spec_guess_object_list(
      list(
        list(x = 1.5),
        list(x = 1),
        list()
      )
    ),
    spec_df(x = tib_dbl("x", FALSE))
  )
})

test_that("can guess tib_unspecified in an object_list", {
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

test_that("can guess object_list of length one (#50)", {
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
