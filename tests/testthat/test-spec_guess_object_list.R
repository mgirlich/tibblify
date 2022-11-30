
# get_required() ----------------------------------------------------------


# guess_object_list_field_spec() ------------------------------------------

guess_ol_field <- function(value,
                           name = "x",
                           empty_list_unspecified = FALSE,
                           simplify_list = FALSE) {
  guess_object_list_field_spec(
    value = value,
    name = name,
    empty_list_unspecified = empty_list_unspecified,
    simplify_list = simplify_list
  )
}

test_that("can guess scalar elements", {
  expect_equal(
    guess_ol_field(list(TRUE, FALSE)),
    tib_lgl("x")
  )

  expect_equal(
    guess_ol_field(list(new_datetime(1), new_datetime(2))),
    tib_scalar("x", new_datetime())
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    guess_ol_field(list(x = x_rat, x_rat)),
    tib_scalar("x", x_rat)
  )
})

test_that("can guess scalar elements with NULL", {
  expect_equal(
    guess_ol_field(list(1L, NULL)),
    tib_int("x")
  )
})

test_that("POSIXlt is converted to POSIXct", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    guess_ol_field(list(x_posixlt, x_posixlt)),
    tib_scalar("x", vctrs::new_datetime(tzone = "UTC"))
  )
})

test_that("respect empty_list_unspecified for scalar elements", {
  x <- list(x = 1L, list())
  expect_equal(
    guess_ol_field(x, empty_list_unspecified = FALSE),
    tib_variant("x")
  )

  # this should be `tib_vector` because a list cannot occur for a scalar
  x <- list(list(x = 1L), list(x = list()))
  expect_equal(
    guess_tspec_object_list(x, empty_list_unspecified = TRUE),
    tspec_df(
      vector_allows_empty_list = TRUE,
      x = tib_int_vec("x")
    )
  )
})

test_that("can guess vector elements", {
  expect_equal(
    guess_ol_field(list(c(TRUE, FALSE), FALSE)),
    tib_lgl_vec("x")
  )

  expect_equal(
    guess_ol_field(
      list(
        new_datetime(1),
        c(new_datetime(2), new_datetime(3))
      )
    ),
    tib_vector("x", new_datetime())
  )

  expect_equal(
    guess_ol_field(list(x = 1L, integer())),
    tib_int_vec("x")
  )
})

test_that("respect empty_list_unspecified for vector elements", {
  expect_equal(
    guess_ol_field(list(x = 1:2, list()), empty_list_unspecified = FALSE),
    tib_variant("x")
  )

  x <- list(list(x = 1:2), list(x = list()))
  expect_equal(
    guess_tspec_object_list(x, empty_list_unspecified = TRUE),
    tspec_df(
      vector_allows_empty_list = TRUE,
      x = tib_int_vec("x")
    )
  )
})

test_that("can guess vector input form", {
  expect_equal(
    guess_ol_field(list(list(1, 2), list()), simplify_list = TRUE, empty_list_unspecified = FALSE),
    tib_dbl_vec("x", input_form = "scalar_list")
  )

  # checks size
  expect_equal(
    guess_ol_field(list(list(1, 1:2)), simplify_list = TRUE, empty_list_unspecified = FALSE),
    tib_variant("x")
  )

  expect_equal(
    guess_ol_field( list(list(1, integer())), simplify_list = TRUE, empty_list_unspecified = FALSE),
    tib_variant("x")
  )

  # there need to be enough different elements to be recognized as input_form = "object"
  # TODO should ask the user?
  skip("improve guessing logic")
  x <- list(
    list(x = list(a = 1, b = 2)),
    list(x = list(c = 1, d = 1, e = 1, f = 1)),
    list(x = list(g = 1, h = 1, i = 1, j = 1))
  )
  expect_equal(
    guess_tspec_object_list(x, simplify_list = TRUE, empty_list_unspecified = FALSE),
    tspec_df(x = tib_dbl_vec("x", input_form = "object"))
  )
})

test_that("can guess tib_variant", {
  expect_equal(
    guess_ol_field(list(list(TRUE, "a"), list(FALSE, "b"))),
    tib_variant("x")
  )

  expect_equal(
    guess_ol_field(list("a", 1)),
    tib_variant("x")
  )
})

test_that("can handle non-vector elements", {
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    guess_ol_field(list(model, 1L)),
    tib_variant("x")
  )
})

test_that("can guess object elements", {
  expect_equal(
    guess_ol_field(list(list(a = 1L, b = "a"), list(a = 2L, b = "b"))),
    tib_row("x", a = tib_int("a"), b = tib_chr("b"))
  )

  expect_equal(
    guess_ol_field(list(list(a = 1L), list(a = 2:3))),
    tib_row("x", a = tib_int_vec("a"))
  )

  expect_equal(
    guess_ol_field(list(list(a = 1L), list(a = "a"))),
    tib_row("x", a = tib_variant("a"))
  )
})

test_that("respect empty_list_unspecified for object elements", {
  x <- list(list(x = list(y = 1:2)), list(x = list(y = list())))
  expect_equal(
    guess_tspec_object_list(x, empty_list_unspecified = FALSE),
    tspec_df(x = tib_row("x", y = tib_variant("y")))
  )

  expect_equal(
    guess_tspec_object_list(x, empty_list_unspecified = TRUE),
    tspec_df(
      vector_allows_empty_list = TRUE,
      x = tib_row("x", y = tib_int_vec("y"))
    )
  )
})

test_that("can guess tib_df", {
  expect_equal(
    guess_tspec_object_list(
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
    tspec_df(x = tib_df("x", a = tib_dbl("a")))
  )
})

test_that("can guess tib_unspecified", {
  expect_equal(guess_tspec_object_list(list(list(x = NULL), list(x = NULL))), tspec_df(x = tib_unspecified("x")))
  expect_equal(
    guess_tspec_object_list(
      list(
        list(x = list(NULL, NULL)),
        list(x = list(NULL))
      )
    ),
    tspec_df(x = tib_unspecified("x"))
  )

  # in a row
  # TODO
  # expect_equal(
  #   guess_tspec_object_list(list(list(x = list(a = NULL)), list(x = list(a = NULL)))),
  #   tspec_df(x = tib_row("x", a = tib_unspecified("a")))
  # )

  # in a df
  expect_equal(
    guess_tspec_object_list(
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
    tspec_df(x = tib_df("x", a = tib_unspecified("a")))
  )
})

test_that("order of fields does not matter", {
  expect_equal(
    guess_tspec_object_list(list(list(x = TRUE, y = 1:3), list(z = "a", y = 2L, x = FALSE))),
    tspec_df(x = tib_lgl("x"), y = tib_int_vec("y"), z = tib_chr("z", required = FALSE))
  )

  expect_equal(
    guess_tspec_object_list(
      list(
        list(x = list(a = 1L, b = "a")),
        list(x = list(b = "b", a = 2L))
      )
    ),
    tspec_df(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess object_list of length one (#50)", {
  expect_equal(
    guess_tspec(list(list(x = 1, y = 2))),
    tspec_df(
      x = tib_dbl("x"),
      y = tib_dbl("y"),
    )
  )
})
