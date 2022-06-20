test_that("can guess scalar columns", {
  expect_equal(
    spec_guess_df(
      tibble(
        lgl = TRUE,
        dtt = vctrs::new_datetime()
      )
    ),
    spec_df(
      lgl = tib_lgl("lgl"),
      dtt = tib_scalar("dtt", ptype = vctrs::new_datetime())
    )
  )

  # also for record types
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    spec_guess_df(tibble(x = x_posixlt)),
    spec_df(x = tib_scalar("x", ptype = vec_ptype(x_posixlt)))
  )
})

test_that("can guess scalar NA columns", {
  expect_equal(
    spec_guess_df(tibble(int = NA_integer_)),
    spec_df(int = tib_int("int"))
  )

  na_date <- vec_init(vctrs::new_date())
  expect_equal(
    spec_guess_df(tibble(date = na_date)),
    spec_df(date = tib_scalar("date", ptype = vctrs::new_date()))
  )

  skip("Unclear what to do about logical NA")
  # this gives `tib_unspecified` because `vec_ptype(NA)` is `vctrs::unspecified()`
  # probably this makes most sense
  expect_equal(
    spec_guess_df(tibble(lgl = NA)),
    spec_df(lgl = tib_unspecified("lgl"))
  )
})

test_that("can guess vector columns", {
  expect_equal(
    spec_guess_df(
      tibble(
        lgl_vec = list(TRUE),
        dtt_vec = list(vctrs::new_datetime()),
      )
    ),
    spec_df(
      lgl_vec = tib_lgl_vec("lgl_vec"),
      dtt_vec = tib_vector("dtt_vec", ptype = vctrs::new_datetime())
    )
  )

  # also for record types
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    spec_guess_df(tibble(x = list(x_posixlt))),
    spec_df(x = tib_vector("x", ptype = vec_ptype(x_posixlt)))
  )
})

test_that("can guess list columns", {
  expect_equal(
    spec_guess_df(tibble(x = list(1, "a"))),
    spec_df(x = tib_list("x"))
  )

  # non-vector objects are okay in lists
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    spec_guess_df(tibble(x = list(model, 1))),
    spec_df(x = tib_list("x"))
  )

  skip("Unclear what to do about list columns with only NULL")
  expect_equal(
    spec_guess_df(tibble(x = list(NULL, NULL))),
    spec_df(x = tib_unspecified("x"))
  )
})

test_that("can guess tibble columns", {
  # scalar
  expect_equal(
    spec_guess_df(tibble(df = tibble(int = 1L, chr = "a"))),
    spec_df(
      df = tib_row(
        "df",
        int = tib_int("int"),
        chr = tib_chr("chr")
      )
    )
  )

  # vector
  expect_equal(
    spec_guess_df(tibble(df = tibble(int_vec = list(1L)))),
    spec_df(
      df = tib_row("df", int_vec = tib_int_vec("int_vec"))
    )
  )

  # mixed
  expect_equal(
    spec_guess_df(tibble(df = tibble(x = list(1L, "a")))),
    spec_df(
      df = tib_row("df", x = tib_list("x"))
    )
  )

  # tibble -> recursion
  expect_equal(
    spec_guess_df(tibble(df = tibble(x = tibble(y = 1L)))),
    spec_df(
      df = tib_row("df", x = tib_row("x", y = tib_int("y")))
    )
  )
})

test_that("can guess list of tibble columns", {
  # scalar
  expect_equal(
    spec_guess_df(
      tibble(
        df_list = list(
          tibble(dbl = 1:2),
          tibble(dbl = 2.5, chr = "a")
        )
      )
    ),
    spec_df(
      df_list = tib_df(
        "df_list",
        dbl = tib_dbl("dbl"),
        chr = tib_chr("chr")
      )
    )
  )

  # vector
  expect_equal(
    spec_guess_df(
      tibble(
        df_list = list(
          tibble(dbl_vec = list(1, 2:3)),
          tibble(dbl_vec = list(2.5))
        )
      )
    ),
    spec_df(
      df_list = tib_df(
        "df_list",
        dbl_vec = tib_dbl_vec("dbl_vec")
      )
    )
  )

  # mixed
  expect_equal(
    spec_guess_df(
      tibble(
        df_list = list(
          tibble(x = list(1, 2:3)),
          tibble(x = list("a"))
        )
      )
    ),
    spec_df(
      df_list = tib_df(
        "df_list",
        x = tib_list("x")
      )
    )
  )

  # tibble -> recursion
  expect_equal(
    spec_guess_df(
      tibble(
        df_list = list(
          tibble(x = tibble(y = 1:2)),
          tibble(x = tibble(y = 1L))
        )
      )
    ),
    spec_df(
      df_list = tib_df(
        "df_list",
        x = tib_row("x", y = tib_int("y"))
      )
    )
  )
})

test_that("can guess required for list of tibble columns", {
  skip("Not yet working - #70")
  expect_equal(
    spec_guess_df(
      tibble(
        x = list(
          tibble(a = 1, b = "a"),
          tibble(a = 2)
        )
      )
    ),
    spec_df(
      x = tib_df(
        "x",
        a = tib_dbl("a"),
        b = tib_chr("b", required = FALSE)
      )
    )
  )
})

test_that("can guess spec for data frames with nested df columns", {
  # row in row element
  expect_equal(
    spec_guess_df(
      tibble(df = tibble(df2 = tibble(int2 = 1L, chr2 = "a")))
    ),
    spec_df(
      df = tib_row(
        "df",
        df2 = tib_row(
          "df2",
          int2 = tib_int("int2"),
          chr2 = tib_chr("chr2")
        )
      )
    )
  )

  # df in row element
  expect_equal(
    spec_guess_df(
      tibble(
        df = tibble(
          df2 = list(
            tibble(dbl2 = 1L),
            tibble(dbl2 = 2.5, chr2 = "a")
          )
        )
      )
    ),
    spec_df(
      df = tib_row(
        "df",
        df2 = tib_df(
          "df2",
          dbl2 = tib_dbl("dbl2"),
          chr2 = tib_chr("chr2")
        )
      )
    )
  )
})


test_that("can guess spec for data frames with nested list of df columns", {
  # row in df element
  expect_equal(
    spec_guess_df(
      tibble(df = list(tibble(df2 = tibble(int2 = 1L, chr2 = "a"))))
    ),
    spec_df(
      df = tib_df(
        "df",
        df2 = tib_row(
          "df2",
          int2 = tib_int("int2"),
          chr2 = tib_chr("chr2")
        )
      )
    )
  )

  # df in row element
  expect_equal(
    spec_guess_df(
      tibble(
        df = list(
          tibble(
            df2 = list(
              tibble(dbl2 = 1L),
              tibble(dbl2 = 2.5, chr2 = "a")
            )
          )
        )
      )
    ),
    spec_df(
      df = tib_df(
        "df",
        df2 = tib_df(
          "df2",
          dbl2 = tib_dbl("dbl2"),
          chr2 = tib_chr("chr2")
        )
      )
    )
  )
})

test_that("gives nice errors", {
  expect_snapshot({
    (expect_error(spec_guess_df(list(a = 1))))
  })
})
