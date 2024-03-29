
# scalar columns ----------------------------------------------------------

test_that("can guess scalar columns", {
  expect_equal(
    col_to_spec(TRUE, "lgl", FALSE),
    tib_lgl("lgl")
  )
  expect_equal(
    col_to_spec(vctrs::new_datetime(), "dtt", FALSE),
    tib_scalar("dtt", ptype = vctrs::new_datetime())
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    col_to_spec(x_rat, "x", FALSE),
    tib_scalar("x", x_rat)
  )
})

test_that("scalar POSIXlt is converted to POSIXct", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    col_to_spec(x_posixlt, "x", FALSE),
    tib_scalar("x", ptype = vctrs::new_datetime())
  )
})

test_that("can guess scalar NA columns", {
  # typed NA creates tib_scalar
  expect_equal(
    col_to_spec(NA_integer_, "int", FALSE),
    tib_int("int")
  )

  na_date <- vec_init(vctrs::new_date())
  expect_equal(
    col_to_spec(na_date, "date", FALSE),
    tib_scalar("date", ptype = vctrs::new_date())
  )

  # simple NA creates tib_unspecified
  expect_equal(
    col_to_spec(NA, "lgl", FALSE),
    tib_unspecified("lgl")
  )
})


# vector columns ----------------------------------------------------------

test_that("can guess vector columns", {
  expect_equal(
    col_to_spec(list(TRUE), "lgl_vec", FALSE),
    tib_lgl_vec("lgl_vec")
  )
  expect_equal(
    col_to_spec(list(vctrs::new_datetime()), "dtt_vec", FALSE),
    tib_vector("dtt_vec", ptype = vctrs::new_datetime())
  )

  # also for record types
  x_rat <- new_rational(1, 2)
  expect_equal(
    col_to_spec(list(x_rat), "x", FALSE),
    tib_vector("x", x_rat)
  )
})

test_that("vector POSIXlt is converted to POSIXct", {
  x_posixlt <- as.POSIXlt(vctrs::new_date(0))
  expect_equal(
    col_to_spec(list(x_posixlt), "x", FALSE),
    tib_vector("x", ptype = vctrs::new_datetime())
  )
})

test_that("can guess vector NA columns", {
  # TODO maybe this could also be `tib_unspecified()`?
  expect_equal(
    col_to_spec(list(c(NA, NA), NA), "x", FALSE),
    tib_lgl_vec("x")
  )
})

test_that("respect empty_list_unspecified for vector columns", {
  expect_equal(
    col_to_spec(list(1:2, list()), "int_vec", FALSE),
    tib_variant("int_vec")
  )

  # needs to check against `tspec_df()` for `vector_allows_empty_list`
  x <- tibble(int_vec = list(1:2, list()))
  expect_equal(
    guess_tspec_df(x, empty_list_unspecified = TRUE),
    tspec_df(
      vector_allows_empty_list = TRUE,
      int_vec = tib_int_vec("int_vec")
    )
  )
})

test_that("can guess list of NULL columns", {
  expect_equal(
    col_to_spec(list(NULL, NULL), "x", FALSE),
    tib_unspecified("x")
  )
})

test_that("can guess list of columns", {
  expect_equal(
    col_to_spec(list_of(1L, 2:3), "x", FALSE),
    tib_int_vec("x")
  )

  expect_equal(
    col_to_spec(list_of(.ptype = integer()), "x", FALSE),
    tib_int_vec("x")
  )
})


# variant columns ---------------------------------------------------------

test_that("can guess mixed columns", {
  expect_equal(
    col_to_spec(list(1, "a"), "x", FALSE),
    tib_variant("x")
  )
})

test_that("can guess non-vector objects", {
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    col_to_spec(list(1, model), "x", FALSE),
    tib_variant("x")
  )
})


# tibble columns ----------------------------------------------------------

test_that("can guess tibble columns", {
  # scalar
  expect_equal(
    col_to_spec(tibble(int = 1L, chr = "a"), "df", FALSE),
    tib_row(
      "df",
      int = tib_int("int"),
      chr = tib_chr("chr")
    )
  )

  # vector
  expect_equal(
    col_to_spec(tibble(int_vec = list(1L)), "df", FALSE),
    tib_row("df", int_vec = tib_int_vec("int_vec"))
  )

  # mixed
  expect_equal(
    col_to_spec(tibble(x = list(1L, "a")), "df", FALSE),
    tib_row("df", x = tib_variant("x"))
  )

  # tibble -> recursion
  expect_equal(
    col_to_spec(tibble(x = tibble(y = 1L)), "df", FALSE),
    tib_row("df", x = tib_row("x", y = tib_int("y")))
  )
})

test_that("respect empty_list_unspecified in tibble columns", {
  x <- tibble(x = tibble(int_vec = list(1:2, list())))
  expect_equal(
    guess_tspec_df(x, empty_list_unspecified = FALSE),
    tspec_df(
      tib_row("x", tib_variant("int_vec"))
    )
  )

  expect_equal(
    guess_tspec_df(x, empty_list_unspecified = TRUE),
    tspec_df(
      vector_allows_empty_list = TRUE,
      tib_row("x", tib_int_vec("int_vec"))
    )
  )
})


# list of tibble columns --------------------------------------------------

test_that("can guess spec for list_of column", {
  expect_equal(
    guess_tspec_df(
      tibble(
        x = list_of(1L, 2:3),
        y = list_of(tibble(a = 1:2)),
        z = list_of(tibble(a = list(1, 2)))
      )
    ),
    tspec_df(
      tib_int_vec("x"),
      tib_df("y", tib_int("a")),
      tib_df("z", tib_dbl_vec("a")),
    )
  )

  expect_equal(
    guess_tspec_df(
      tibble(x = list_of(tibble(a = list(1, "a"))))
    ),
    tspec_df(tib_df("x", tib_variant("a")))
  )
})

test_that("can guess list of tibble columns", {
  # scalar
  expect_equal(
    guess_tspec_df(
      tibble(
        df_list = list(
          tibble(dbl = 1:2),
          tibble(dbl = 2.5, chr = "a")
        )
      )
    ),
    tspec_df(
      df_list = tib_df(
        "df_list",
        dbl = tib_dbl("dbl"),
        chr = tib_chr("chr", required = FALSE)
      )
    )
  )

  # vector
  expect_equal(
    guess_tspec_df(
      tibble(
        df_list = list(
          tibble(dbl_vec = list(1, 2:3)),
          tibble(dbl_vec = list(2.5))
        )
      )
    ),
    tspec_df(
      df_list = tib_df(
        "df_list",
        dbl_vec = tib_dbl_vec("dbl_vec")
      )
    )
  )

  # mixed
  expect_equal(
    guess_tspec_df(
      tibble(
        df_list = list(
          tibble(x = list(1, 2:3)),
          tibble(x = list("a"))
        )
      )
    ),
    tspec_df(
      df_list = tib_df(
        "df_list",
        x = tib_variant("x")
      )
    )
  )

  # tibble -> recursion
  expect_equal(
    guess_tspec_df(
      tibble(
        df_list = list(
          tibble(x = tibble(y = 1:2)),
          tibble(x = tibble(y = 1L))
        )
      )
    ),
    tspec_df(
      df_list = tib_df(
        "df_list",
        x = tib_row("x", y = tib_int("y"))
      )
    )
  )
})

test_that("respect empty_list_unspecified for list of tibble columns", {
  x <- tibble(x = list(tibble(int_vec = list(1:2, list()))))
  expect_equal(
    guess_tspec_df(x, empty_list_unspecified = FALSE),
    tspec_df(
      x = tib_df(
        "x",
        int_vec = tib_variant("int_vec")
      )
    )
  )

  expect_equal(
    guess_tspec_df(x, empty_list_unspecified = TRUE),
    tspec_df(
      vector_allows_empty_list = TRUE,
      tib_df("x", tib_int_vec("int_vec"))
    )
  )
})

test_that("can guess required for list of tibble columns", {
  expect_equal(
    guess_tspec_df(
      tibble(
        x = list(
          tibble(a = 1, b = "a"),
          tibble(a = 2)
        )
      )
    ),
    tspec_df(
      x = tib_df(
        "x",
        a = tib_dbl("a"),
        b = tib_chr("b", required = FALSE)
      )
    )
  )
})

test_that("can guess spec for nested df columns", {
  # row in row element
  expect_equal(
    col_to_spec(tibble(df2 = tibble(int2 = 1L, chr2 = "a")), "df", FALSE),
    tib_row(
      "df",
      df2 = tib_row(
        "df2",
        int2 = tib_int("int2"),
        chr2 = tib_chr("chr2")
      )
    )
  )

  # df in row element
  expect_equal(
    col_to_spec(
      tibble(
        df2 = list(
          tibble(dbl2 = 1L),
          tibble(dbl2 = 2.5, chr2 = "a")
        )
      ),
      "df",
      FALSE
    ),
    tib_row(
      "df",
      df2 = tib_df(
        "df2",
        dbl2 = tib_dbl("dbl2"),
        chr2 = tib_chr("chr2", required = FALSE)
      )
    )
  )
})


test_that("can guess spec for nested list of df columns", {
  # row in df element
  expect_equal(
    col_to_spec(list(tibble(df2 = tibble(int2 = 1L, chr2 = "a"))), "df", FALSE),
    tib_df(
      "df",
      df2 = tib_row(
        "df2",
        int2 = tib_int("int2"),
        chr2 = tib_chr("chr2")
      )
    )
  )

  # df in df element
  expect_equal(
    col_to_spec(
      list(
        tibble(
          df2 = list(
            tibble(dbl2 = 1L),
            tibble(dbl2 = 2.5, chr2 = "a")
          )
        )
      ),
      "df",
      FALSE
    ),
    tib_df(
      "df",
      df2 = tib_df(
        "df2",
        dbl2 = tib_dbl("dbl2"),
        chr2 = tib_chr("chr2", required = FALSE)
      )
    )
  )
})


# edge cases --------------------------------------------------------------

test_that("can guess 0 row tibbles", {
  expect_equal(
    guess_tspec_df(
      tibble(
        int = integer(),
        dbl_vec = list_of(.ptype = 1),
        row = tibble(chr = character()),
        df = list_of(.ptype = tibble(dbl = 1, chr = "a")),
        df2 = list_of(.ptype = tibble(chr_vec = list_of(.ptype = "a")))
      )
    ),
    tspec_df(
      tib_int("int"),
      tib_dbl_vec("dbl_vec"),
      tib_row("row", tib_chr("chr")),
      tib_df("df", tib_dbl("dbl"), tib_chr("chr")),
      tib_df("df2", tib_chr_vec("chr_vec"))
    )
  )
})

test_that("gives nice errors", {
  expect_snapshot({
    (expect_error(guess_tspec_df(list(a = 1))))
    (expect_error(guess_tspec_df(1:3)))
  })
})

test_that("inform about unspecified elements", {
  expect_snapshot({
    guess_tspec_df(tibble(lgl = NA), inform_unspecified = TRUE)
  })
})
