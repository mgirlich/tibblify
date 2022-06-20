test_that("can guess tib_scalar in an object", {
  expect_equal(spec_guess_object(list(x = TRUE)), spec_object(x = tib_lgl("x")))
  expect_equal(
    spec_guess_object(list(x = new_datetime(1))),
    spec_object(x = tib_scalar("x", new_datetime()))
  )
})

test_that("can guess tib_vector in an object", {
  expect_equal(spec_guess_object(list(x = c(TRUE, FALSE))), spec_object(x = tib_lgl_vec("x")))
  expect_equal(
    spec_guess_object(list(x = c(new_datetime(1), new_datetime(2)))),
    spec_object(x = tib_vector("x", new_datetime()))
  )
})

test_that("can guess tib_vector for a scalar list in an object", {
  expect_equal(
    spec_guess_object(list(x = list(TRUE, TRUE))),
    spec_object(x = tib_lgl_vec("x", transform = make_unchop(logical()))),
    ignore_function_env = TRUE
  )

  expect_equal(
    spec_guess_object(list(x = list(new_datetime(1)))),
    spec_object(x = tib_vector("x", new_datetime(), transform = make_unchop(new_datetime()))),
    ignore_function_env = TRUE
  )
})

test_that("can guess tib_list in an object", {
  expect_equal(spec_guess_object(list(x = list(TRUE, "a"))), spec_object(x = tib_list("x")))
})

test_that("can guess tib_row in an object", {
  expect_equal(
    spec_guess_object(list(x = list(a = 1L, b = "a"))),
    spec_object(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess tib_row with a scalar list in an object", {
  expect_equal(
    spec_guess_object(list(x = list(a = list(1L, 2L), b = "a"))),
    spec_object(
      x = tib_row(
        "x",
        a = tib_int_vec("a", transform = make_unchop(integer())),
        b = tib_chr("b")
      )
    ),
    ignore_function_env = TRUE
  )
})

test_that("can guess tib_df in an object", {
  expect_equal(
    spec_guess_object(
      list(
        x = list(
          list(a = 1L),
          list(a = 2L)
        )
      )
    ),
    spec_object(x = tib_df("x", a = tib_int("a")))
  )
})

test_that("can guess tib_unspecified for an object", {
  expect_equal(spec_guess_object(list(x = NULL)), spec_object(x = tib_unspecified("x")))
  expect_equal(spec_guess_object(list(x = list(NULL, NULL))), spec_object(x = tib_unspecified("x")))

  # in a row
  expect_equal(
    spec_guess_object(list(x = list(a = NULL))),
    spec_object(x = tib_row("x", a = tib_unspecified("a")))
  )

  # in a df
  expect_equal(
    spec_guess_object(
      list(
        x = list(
          list(a = NULL),
          list(a = NULL)
        )
      )
    ),
    spec_object(x = tib_df("x", a = tib_unspecified("a")))
  )
})
