# spec_df -----------------------------------------------------------------

test_that("can guess tib_scalar in an object_list", {
  expect_equal(
    spec_guess(list(list(x = TRUE), list(x = FALSE))),
    spec_df(x = tib_lgl("x"))
  )
  expect_equal(
    spec_guess(list(list(x = new_datetime(1)), list(x = new_datetime(2)))),
    spec_df(x = tib_scalar("x", new_datetime()))
  )
})

test_that("can guess tib_vector in an object_list", {
  expect_equal(
    spec_guess(list(list(x = c(TRUE, FALSE)), list(x = FALSE))),
    spec_df(x = tib_lgl_vec("x"))
  )
  expect_equal(
    spec_guess(list(list(x = "a"), list(x = c("b", "c")))),
    spec_df(x = tib_chr_vec("x"))
  )
  expect_equal(
    spec_guess(
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
    spec_guess(
      list(
        list(x = list(TRUE, "a")),
        list(x = list(FALSE, "b"))
      )
    ),
    spec_df(x = tib_list("x"))
  )

  expect_equal(
    spec_guess(
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
    spec_guess(
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
    spec_guess(
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
    spec_guess(
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
  expect_equal(spec_guess(list(list(x = NULL), list(x = NULL))), spec_df(x = tib_unspecified("x")))
  expect_equal(
    spec_guess(
      list(
        list(x = list(NULL, NULL)),
        list(x = list(NULL))
      )
    ),
    spec_df(x = tib_unspecified("x"))
  )

  # in a row
  expect_equal(
    spec_guess(list(list(x = list(a = NULL)), list(x = list(a = NULL)))),
    spec_df(x = tib_row("x", a = tib_unspecified("a")))
  )

  # in a df
  expect_equal(
    spec_guess(
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
    spec_guess(
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

# diverse -----------------------------------------------------------------

test_that("can guess spec for discog", {
  expect_snapshot(spec_guess(discog) %>% print())
})

test_that("can guess spec for gh_users", {
  expect_snapshot(spec_guess(gh_users) %>% print())
})

test_that("can guess spec for gh_repos", {
  expect_snapshot(spec_guess(gh_repos) %>% print())
})

test_that("can guess spec for got_chars", {
  skip("not yet decided")
  # `got_chars[[19]]$aliases` is an empty list `list()` --> cannot (yet?) simplify to character
  expect_snapshot(spec_guess(got_chars) %>% print())
})

read_sample_json <- function(x) {
  path <- system.file("jsonexamples", x, package = "tibblify")
  jsonlite::fromJSON(path, simplifyDataFrame = FALSE)
}

test_that("can guess spec for citm_catalog", {
  x <- read_sample_json("citm_catalog.json")
  x$areaNames <- x$areaNames[1:3]
  x$events <- x$events[1:3]
  x$performances <- x$performances[1:3]
  x$seatCategoryNames <- x$seatCategoryNames[1:3]
  x$subTopicNames <- x$subTopicNames[1:3]

  expect_snapshot(spec_guess(x))

  expect_snapshot(spec_guess_list(x, simplify_list = FALSE))
})

test_that("can guess spec for gsoc-2018", {
  x <- read_sample_json("gsoc-2018.json")
  expect_snapshot(spec_guess(x))
})

test_that("can guess spec for twitter", {
  x <- read_sample_json("twitter.json")
  expect_snapshot(spec_guess(x))
})