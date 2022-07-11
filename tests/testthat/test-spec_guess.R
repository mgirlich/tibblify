test_that("can guess spec for discog", {
  expect_snapshot(tspec_guess(discog) %>% print())
})

test_that("can guess spec for gh_users", {
  expect_snapshot(tspec_guess(gh_users) %>% print())
})

test_that("can guess spec for gh_repos", {
  expect_snapshot(tspec_guess(gh_repos) %>% print())
})

test_that("can guess spec for got_chars", {
  spec <- tspec_guess(got_chars)
  expect_snapshot(spec)
  expect_equal(spec$fields$aliases, tib_variant("aliases"))
  expect_equal(spec$fields$allegiances, tib_variant("allegiances"))
  expect_equal(spec$fields$books, tib_variant("books"))

  spec2 <- tspec_guess(got_chars, empty_list_unspecified = TRUE)
  expect_equal(spec2$fields$aliases, tib_chr_vec("aliases"))
  expect_equal(spec2$fields$allegiances, tib_chr_vec("allegiances"))
  expect_equal(spec2$fields$books, tib_chr_vec("books"))
})

test_that("can guess spec for citm_catalog", {
  x <- read_sample_json("citm_catalog.json")
  x$areaNames <- x$areaNames[1:3]
  x$events <- x$events[1:3]
  x$performances <- x$performances[1:3]
  x$seatCategoryNames <- x$seatCategoryNames[1:3]
  x$subTopicNames <- x$subTopicNames[1:3]

  # TODO `$seatCategoryNames`, `$subTopicNames`, `$topicNames` can be simplifed to a character vector
  # TODO think about `$topicSubTopics`
  expect_snapshot(tspec_guess(x))

  expect_snapshot(tspec_guess_list(x, simplify_list = FALSE))
})

test_that("can guess spec for gsoc-2018", {
  x <- read_sample_json("gsoc-2018.json")
  expect_snapshot(tspec_guess(x))
})

test_that("can guess spec for twitter", {
  x <- read_sample_json("twitter.json")
  expect_snapshot(tspec_guess(x))
})

test_that("informing about unspecified looks good", {
  spec <- tspec_df(
    tib_int("1int"),
    tib_unspecified("1un"),
    tib_df(
      "1df",
      tib_int("2int"),
      tib_unspecified("2un"),
      tib_row(
        "2row",
        `3un` = tib_unspecified("key"),
        `3un2` = tib_unspecified("key2"),
      )
    ),
    tib_row(
      "1row",
      tib_unspecified("2un2"),
      `2un3` = tib_unspecified("key")
    )
  )
  expect_snapshot({spec_inform_unspecified(spec)})
})
