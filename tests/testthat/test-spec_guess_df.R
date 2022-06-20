test_that("can guess spec for data frames", {
  # scalar elements
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

  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    spec_guess_df(tibble(x = x_posixlt)),
    spec_df(x = tib_scalar("x", ptype = vec_ptype(x_posixlt)))
  )

  # vector elements
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

  expect_equal(
    spec_guess_df(tibble(x = list(x_posixlt))),
    spec_df(x = tib_vector("x", ptype = vec_ptype(x_posixlt)))
  )

  # list elements
  expect_equal(
    spec_guess_df(tibble(x = list(1, "a"))),
    spec_df(x = tib_list("x"))
  )

  expect_equal(
    spec_guess_df(tibble(x = list(NULL, NULL))),
    spec_df(x = tib_unspecified("x"))
  )

  # row elements
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

  # df elements
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
