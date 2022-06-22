test_that("can guess scalar elements", {
  expect_equal(
    spec_guess_object(list(x = TRUE)),
    spec_object(x = tib_lgl("x"))
  )

  expect_equal(
    spec_guess_object(list(x = new_datetime(1))),
    spec_object(x = tib_scalar("x", new_datetime()))
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    spec_guess_object(list(x = x_rat)),
    spec_object(x = tib_scalar("x", ptype = x_rat))
  )
})

test_that("POSIXlt is converted to POSIXct", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    spec_guess_object(list(x = x_posixlt)),
    spec_object(x = tib_scalar("x", vctrs::new_datetime(tzone = "")))
  )
})

test_that("can handle non-vector elements", {
  skip("Not yet working - #76")
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  spec_guess_object(list(x = model))
})

test_that("can guess vector elements", {
  expect_equal(
    spec_guess_object(list(x = c(TRUE, FALSE))),
    spec_object(x = tib_lgl_vec("x"))
  )

  expect_equal(
    spec_guess_object(list(x = c(new_datetime(1), new_datetime(2)))),
    spec_object(x = tib_vector("x", new_datetime()))
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    spec_guess_object(list(x = c(x_rat, x_rat))),
    spec_object(x = tib_vector("x", ptype = x_rat))
  )
})

test_that("POSIXlt is converted to POSIXct for vector elements", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    spec_guess_object(list(x = c(x_posixlt, x_posixlt))),
    spec_object(x = tib_vector("x", ptype = vctrs::new_datetime()))
  )
})

test_that("can guess tib_vector for a scalar list", {
  # FIXME this should get a different API
  # https://github.com/mgirlich/tibblify/pull/69
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

test_that("can guess mixed elements", {
  expect_equal(
    spec_guess_object(list(x = list(TRUE, "a"))),
    spec_object(x = tib_variant("x"))
  )
})

test_that("non-vector objects work", {
  skip("handling of non-vector objects not yet decided - #84")
  # non-vector objects are okay in lists
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    spec_guess_object(list(x = list(TRUE, model))),
    spec_object(x = tib_variant("x"))
  )
})

test_that("can guess tib_row", {
  expect_equal(
    spec_guess_object(list(x = list(a = 1L, b = "a"))),
    spec_object(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess tib_row with a scalar list", {
  # FIXME this should get a different API
  # https://github.com/mgirlich/tibblify/pull/69
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

test_that("can guess tib_df", {
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

  expect_equal(
    spec_guess_object(
      list(
        x = list(
          list(a = 1:2L),
          list(a = 2L)
        )
      )
    ),
    spec_object(x = tib_df("x", a = tib_int_vec("a")))
  )

  expect_equal(
    spec_guess_object(
      list(
        x = list(
          list(a = "a"),
          list(a = 1L)
        )
      )
    ),
    spec_object(x = tib_df("x", a = tib_variant("a")))
  )
})

test_that("respect empty_list_unspecified for list of object elements", {
  x <- list(
    x = list(
      list(a = 1L, b = 1:2),
      list(a = list(), b = list())
    )
  )

  expect_equal(
    spec_guess_object(x, empty_list_unspecified = FALSE),
    spec_object(
      x = tib_df(
        "x",
        a = tib_variant("a"),
        b = tib_variant("b")
      )
    )
  )

  expect_equal(
    spec_guess_object(x, empty_list_unspecified = TRUE),
    spec_object(
      x = tib_df(
        "x",
        a = tib_int("a"),
        b = tib_int_vec("b")
      )
    )
  )
})

test_that("can guess required for tib_df", {
  expect_equal(
    spec_guess_object(
      list(
        x = list(
          list(a = 1L, b = "a"),
          list(a = 2L)
        )
      )
    ),
    spec_object(
      x = tib_df(
        "x",
        a = tib_int("a"),
        b = tib_chr("b", required = FALSE)
      )
    )
  )
})

test_that("order of fields for tib_df does not matter", {
  expect_equal(
    spec_guess_object(
      list(
        x = list(
          list(a = 1L, b = "a"),
          list(c = 1:3, b = "c", a = 2L)
        )
      )
    ),
    spec_object(
      x = tib_df(
        "x",
        a = tib_int("a"),
        b = tib_chr("b"),
        c = tib_int_vec("c", required = FALSE)
      )
    )
  )
})

test_that("can guess tib_unspecified for an object", {
  # `NULL` is the missing element in lists
  expect_equal(
    spec_guess_object(list(x = NULL)),
    spec_object(x = tib_unspecified("x"))
  )

  # empty lists could be object or list of object -> unspecified
  expect_equal(
    spec_guess_object(list(x = list()), empty_list_unspecified = FALSE),
    spec_object(x = tib_unspecified("x"))
  )

  # NA could be any scalar value
  expect_equal(
    spec_guess_object(list(x = NA)),
    spec_object(x = tib_unspecified("x"))
  )

  expect_equal(
    spec_guess_object(list(x = list(NULL, NULL))),
    spec_object(x = tib_unspecified("x"))
  )

  # in a row
  expect_equal(
    spec_guess_object(list(x = list(a = NULL))),
    spec_object(x = tib_row("x", a = tib_unspecified("a")))
  )

  expect_equal(
    spec_guess_object(list(x = list(a = list()))),
    spec_object(x = tib_row("x", a = tib_unspecified("a")))
  )

  expect_equal(
    spec_guess_object(list(x = list(a = list())), empty_list_unspecified = FALSE),
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

test_that("gives nice errors", {
  expect_snapshot({
    (expect_error(spec_guess_object(tibble(a = 1))))
    (expect_error(spec_guess_object(1:3)))
  })
})
