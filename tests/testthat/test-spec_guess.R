test_that("checks input", {
  expect_snapshot({
    expect_error(guess_tspec("a"))
  })
})

test_that("can guess spec for discog", {
  expect_snapshot(guess_tspec(discog) %>% print())
})

test_that("can guess spec for gh_users", {
  expect_snapshot(guess_tspec(gh_users) %>% print())
})

test_that("can guess spec for gh_repos", {
  expect_snapshot(guess_tspec(gh_repos) %>% print())
})

test_that("can guess spec for got_chars", {
  spec <- guess_tspec(got_chars)
  expect_snapshot(spec)
  expect_equal(spec$fields$aliases, tib_variant("aliases"))
  expect_equal(spec$fields$allegiances, tib_variant("allegiances"))
  expect_equal(spec$fields$books, tib_variant("books"))

  spec2 <- guess_tspec(got_chars, empty_list_unspecified = TRUE)
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
  expect_snapshot(guess_tspec(x))

  # These fields are empty
  # • blockNames
  # • events->description
  # • events->subjectCode
  # • events->subtitle
  # • performances->logo
  # • performances->name
  # • performances->seatCategories->areas->blockIds
  # • performances->seatMapImage
  # • subjectNames

  expect_snapshot(guess_tspec_list(x, simplify_list = FALSE))
})

test_that("can guess spec for gsoc-2018", {
  x <- read_sample_json("gsoc-2018.json")
  expect_snapshot(guess_tspec(x))
})

test_that("can guess spec for twitter", {
  x <- read_sample_json("twitter.json")
  expect_snapshot(guess_tspec(x))
})

# guess_tspec_list() ------------------------------------------------------

test_that("checks input", {
  # errors for empty input
  expect_snapshot({
    (expect_error(guess_tspec_list(list())))
  })

  # neither object nor object list
  expect_snapshot({
    # not fully named
    (expect_error(guess_tspec_list(list(a = 1, 1))))
    # not unique names
    (expect_error(guess_tspec_list(list(a = 1, a = 1))))
  })
})
