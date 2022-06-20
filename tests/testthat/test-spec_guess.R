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
