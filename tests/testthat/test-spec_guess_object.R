test_that("can guess scalar elements", {
  expect_equal(
    guess_tspec_object(list(x = TRUE)),
    tspec_object(x = tib_lgl("x"))
  )

  expect_equal(
    guess_tspec_object(list(x = new_datetime(1))),
    tspec_object(x = tib_scalar("x", new_datetime()))
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    guess_tspec_object(list(x = x_rat)),
    tspec_object(x = tib_scalar("x", ptype = x_rat))
  )
})

test_that("POSIXlt is converted to POSIXct", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    guess_tspec_object(list(x = x_posixlt)),
    tspec_object(x = tib_scalar("x", vctrs::new_datetime(tzone = "")))
  )
})

test_that("can handle non-vector elements", {
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    guess_tspec_object(list(x = model)),
    tspec_object(x = tib_variant("x"))
  )
})

test_that("can guess vector elements", {
  expect_equal(
    guess_tspec_object(list(x = c(TRUE, FALSE))),
    tspec_object(x = tib_lgl_vec("x"))
  )

  expect_equal(
    guess_tspec_object(list(x = c(new_datetime(1), new_datetime(2)))),
    tspec_object(x = tib_vector("x", new_datetime()))
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    guess_tspec_object(list(x = c(x_rat, x_rat))),
    tspec_object(x = tib_vector("x", ptype = x_rat))
  )
})

test_that("POSIXlt is converted to POSIXct for vector elements", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    guess_tspec_object(list(x = c(x_posixlt, x_posixlt))),
    tspec_object(x = tib_vector("x", ptype = vctrs::new_datetime()))
  )
})

test_that("can guess tib_vector for a scalar list", {
  expect_equal(
    guess_tspec_object(list(x = list(TRUE, TRUE, NULL)), simplify_list = FALSE),
    tspec_object(x = tib_variant("x"))
  )

  expect_equal(
    guess_tspec_object(list(x = list(TRUE, TRUE, NULL)), simplify_list = TRUE),
    tspec_object(x = tib_lgl_vec("x", input_form = "scalar_list"))
  )

  expect_equal(
    guess_tspec_object(list(x = list(new_datetime(1))), simplify_list = TRUE),
    tspec_object(x = tib_vector("x", new_datetime(), input_form = "scalar_list"))
  )

  # checks size
  expect_equal(
    guess_tspec_object(list(x = list(1, 1:2)), simplify_list = TRUE),
    tspec_object(x = tib_variant("x"))
  )

  expect_equal(
    guess_tspec_object(list(x = list(1, integer())), simplify_list = TRUE),
    tspec_object(x = tib_variant("x"))
  )
})

test_that("can guess tib_vector for input form = object", {
  expect_equal(
    guess_tspec_object(list(x = list(a = TRUE, b = TRUE)), simplify_list = TRUE),
    tspec_object(x = tib_lgl_vec("x", input_form = "object"))
  )
})

test_that("can guess mixed elements", {
  expect_equal(
    guess_tspec_object(list(x = list(TRUE, "a"))),
    tspec_object(x = tib_variant("x"))
  )
})

test_that("can handle non-vector elements in list", {
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    guess_tspec_object(list(x = list(model, model))),
    tspec_object(x = tib_variant("x"))
  )
})

test_that("can guess df element", {
  expect_equal(
    guess_tspec_object(list(x = tibble(a = 1L))),
    tspec_object(x = tib_df("x", a = tib_int("a")))
  )
})

test_that("can guess tib_row", {
  expect_equal(
    guess_tspec_object(list(x = list(a = 1L, b = "a"))),
    tspec_object(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess tib_row with a scalar list", {
  expect_equal(
    guess_tspec_object(list(x = list(a = list(1L, 2L), b = "a")), simplify_list = TRUE),
    tspec_object(
      x = tib_row(
        "x",
        a = tib_int_vec("a", input_form = "scalar_list"),
        b = tib_chr("b")
      )
    )
  )
})

test_that("can guess tib_df", {
  expect_equal(
    guess_tspec_object(
      list(
        x = list(
          list(a = 1L),
          list(a = 2L)
        )
      )
    ),
    tspec_object(x = tib_df("x", a = tib_int("a")))
  )

  expect_equal(
    guess_tspec_object(
      list(
        x = list(
          list(a = 1:2L),
          list(a = 2L)
        )
      )
    ),
    tspec_object(x = tib_df("x", a = tib_int_vec("a")))
  )

  expect_equal(
    guess_tspec_object(
      list(
        x = list(
          list(a = "a"),
          list(a = 1L)
        )
      )
    ),
    tspec_object(x = tib_df("x", a = tib_variant("a")))
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
    guess_tspec_object(x, empty_list_unspecified = FALSE),
    tspec_object(
      x = tib_df(
        "x",
        a = tib_variant("a"),
        b = tib_variant("b")
      )
    )
  )

  expect_equal(
    guess_tspec_object(x, empty_list_unspecified = TRUE),
    tspec_object(
      vector_allows_empty_list = TRUE,
      x = tib_df(
        "x",
        a = tib_int_vec("a"),
        b = tib_int_vec("b")
      )
    )
  )
})

test_that("can guess required for tib_df", {
  expect_equal(
    guess_tspec_object(
      list(
        x = list(
          list(a = 1L, b = "a"),
          list(a = 2L)
        )
      )
    ),
    tspec_object(
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
    guess_tspec_object(
      list(
        x = list(
          list(a = 1L, b = "a"),
          list(c = 1:3, b = "c", a = 2L)
        )
      )
    ),
    tspec_object(
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
    guess_tspec_object(list(x = NULL)),
    tspec_object(x = tib_unspecified("x"))
  )

  # empty lists could be object or list of object -> unspecified
  expect_equal(
    guess_tspec_object(list(x = list()), empty_list_unspecified = FALSE),
    tspec_object(x = tib_unspecified("x"))
  )

  # NA could be any scalar value
  expect_equal(
    guess_tspec_object(list(x = NA)),
    tspec_object(x = tib_unspecified("x"))
  )

  # TODO not yet decided
  # expect_equal(
  #   guess_tspec_object(list(x = list(NULL, NULL))),
  #   tspec_object(x = tib_unspecified("x"))
  # )

  # in a row
  expect_equal(
    guess_tspec_object(list(x = list(a = NULL))),
    tspec_object(x = tib_row("x", tib_unspecified("a")))
  )

  # TODO undecided
  # expect_equal(
  #   guess_tspec_object(list(x = list(a = list()))),
  #   tspec_object(x = tib_row("x", tib_unspecified("a")))
  # )

  # TODO undecided
  # expect_equal(
  #   guess_tspec_object(list(x = list(a = list())), empty_list_unspecified = FALSE),
  #   tspec_object(x = tib_row("x", tib_unspecified("a")))
  # )

  # in a df
  expect_equal(
    guess_tspec_object(
      list(
        x = list(
          list(a = NULL),
          list(a = NULL)
        )
      )
    ),
    tspec_object(x = tib_df("x", a = tib_unspecified("a")))
  )
})

test_that("gives nice errors", {
  expect_snapshot({
    (expect_error(guess_tspec_object(tibble(a = 1))))
    (expect_error(guess_tspec_object(1:3)))
  })

  expect_snapshot({
    (expect_error(guess_tspec_object(list(1, a = 1))))
    (expect_error(guess_tspec_object(list(a = 1, a = 1))))
  })
})
