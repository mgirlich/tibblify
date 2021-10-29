tibble <- tibble::tibble

# spec for data frames ----------------------------------------------------

test_that("can guess spec for data frames", {
  # scalar elements
  expect_equal(
    guess_spec(
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

  # vector elements
  expect_equal(
    guess_spec(
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

  # list elements
  expect_equal(
    guess_spec(tibble(x = list(1, "a"))),
    spec_df(x = tib_list("x"))
  )

  expect_equal(
    guess_spec(tibble(x = list(NULL, NULL))),
    spec_df(x = tib_unspecified("x"))
  )

  # row elements
  expect_equal(
    guess_spec(tibble(df = tibble(int = 1L, chr = "a"))),
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
    guess_spec(
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
    guess_spec(
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
    guess_spec(
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
    guess_spec(
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
    guess_spec(
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


# spec_object -------------------------------------------------------------

test_that("can guess tib_scalar in an object", {
  expect_equal(guess_spec(list(x = TRUE)), spec_object(x = tib_lgl("x")))
  expect_equal(
    guess_spec(list(x = new_datetime(1))),
    spec_object(x = tib_scalar("x", new_datetime()))
  )
})

test_that("can guess tib_vector in an object", {
  expect_equal(guess_spec(list(x = c(TRUE, FALSE))), spec_object(x = tib_lgl_vec("x")))
  expect_equal(
    guess_spec(list(x = c(new_datetime(1), new_datetime(2)))),
    spec_object(x = tib_vector("x", new_datetime()))
  )
})

test_that("can guess tib_vector for a scalar list in an object", {
  expect_equal(
    guess_spec(list(x = list(TRUE, TRUE))),
    spec_object(x = tib_lgl_vec("x", transform = make_unchop(logical()))),
    ignore_function_env = TRUE
  )

  expect_equal(
    guess_spec(list(x = list(new_datetime(1)))),
    spec_object(x = tib_vector("x", new_datetime(), transform = make_unchop(new_datetime()))),
    ignore_function_env = TRUE
  )
})

test_that("can guess tib_list in an object", {
  expect_equal(guess_spec(list(x = list(TRUE, "a"))), spec_object(x = tib_list("x")))
})

test_that("can guess tib_row in an object", {
  expect_equal(
    guess_spec(list(x = list(a = 1L, b = "a"))),
    spec_object(x = tib_row("x", a = tib_int("a"), b = tib_chr("b")))
  )
})

test_that("can guess tib_row with a scalar list in an object", {
  expect_equal(
    guess_spec(list(x = list(a = list(1L, 2L), b = "a"))),
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
    guess_spec(
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
  expect_equal(guess_spec(list(x = NULL)), spec_object(x = tib_unspecified("x")))
  expect_equal(guess_spec(list(x = list(NULL, NULL))), spec_object(x = tib_unspecified("x")))

  # in a row
  expect_equal(
    guess_spec(list(x = list(a = NULL))),
    spec_object(x = tib_row("x", a = tib_unspecified("a")))
  )

  # in a df
  expect_equal(
    guess_spec(
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


# spec_df -----------------------------------------------------------------

test_that("can guess tib_scalar in an object_list", {
  expect_equal(
    guess_spec(list(list(x = TRUE), list(x = FALSE))),
    spec_df(x = tib_lgl("x"))
  )
  expect_equal(
    guess_spec(list(list(x = new_datetime(1)), list(x = new_datetime(2)))),
    spec_df(x = tib_scalar("x", new_datetime()))
  )
})

test_that("can guess tib_vector in an object_list", {
  expect_equal(
    guess_spec(list(list(x = c(TRUE, FALSE)), list(x = FALSE))),
    spec_df(x = tib_lgl_vec("x"))
  )
  expect_equal(
    guess_spec(list(list(x = "a"), list(x = c("b", "c")))),
    spec_df(x = tib_chr_vec("x"))
  )
  expect_equal(
    guess_spec(
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
    guess_spec(list(list(x = list(TRUE, "a")))),
    spec_df(x = tib_list("x"))
  )

  expect_equal(
    guess_spec(
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
    guess_spec(
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
    guess_spec(
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
    guess_spec(
      list(
        list(x = 1.5),
        list()
      )
    ),
    spec_df(x = tib_dbl("x", FALSE))
  )
})

test_that("can guess tib_unspecified in an object_list", {
  expect_equal(guess_spec(list(list(x = NULL))), spec_df(x = tib_unspecified("x")))
  expect_equal(guess_spec(list(list(x = list(NULL, NULL)))), spec_df(x = tib_unspecified("x")))

  # in a row
  expect_equal(
    guess_spec(list(list(x = list(a = NULL)))),
    spec_df(x = tib_row("x", a = tib_unspecified("a")))
  )

  # in a df
  expect_equal(
    guess_spec(
      list(
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

# diverse -----------------------------------------------------------------

test_that("can guess spec for discog", {
  expect_snapshot(guess_spec(discog) %>% print())
})

test_that("can guess spec for gh_users", {
  expect_snapshot(guess_spec(gh_users) %>% print())
})

test_that("can guess spec for gh_repos", {
  expect_snapshot(guess_spec(gh_repos) %>% print())
})

test_that("can guess spec for got_chars", {
  skip("not yet decided")
  # `got_chars[[19]]$aliases` is an empty list `list()` --> cannot (yet?) simplify to character
  expect_snapshot(guess_spec(got_chars) %>% print())
})

read_sample_json <- function(x) {
  path <- testthat::test_path("../../inst/jsonexamples", x)
  jsonlite::fromJSON(path, simplifyDataFrame = FALSE)
}

test_that("can guess spec for citm_catalog", {
  x <- read_sample_json("citm_catalog.json")
  x$areaNames <- x$areaNames[1:3]
  x$events <- x$events[1:3]
  x$performances <- x$performances[1:3]
  x$seatCategoryNames <- x$seatCategoryNames[1:3]
  x$subTopicNames <- x$subTopicNames[1:3]

  expect_snapshot(guess_spec(x))

  expect_snapshot(guess_spec(x, simplify_list = FALSE))
})

test_that("can guess spec for gsoc-2018", {
  x <- read_sample_json("gsoc-2018.json")
  expect_snapshot(guess_spec(x))
})

test_that("can guess spec for twitter", {
  x <- read_sample_json("twitter.json")
  expect_snapshot(guess_spec(x))
})
