test_that("is_object() works", {
  # must be a list
  expect_false(is_object(structure(list(x = 1), class = "dummy")))

  # must be fully named
  expect_false(is_object(list(1)))
  expect_false(is_object(list(x = 1, 1)))

  # names must not be NA
  expect_false(is_object(purrr::set_names(list(1, 1), c(NA, "x"))))

  # must not have duplicate names
  expect_false(is_object(list(x = 1, x = 1)))

  # valid objects
  expect_true(is_object(list()))
  expect_true(is_object(list(x = 1)))
  expect_true(is_object(list(x = 1, y = "a")))
})

test_that("is_object_list() works", {
  # must be a list
  expect_false(is_object_list(structure(list(x = 1), class = "dummy")))

  # must be a list of objects
  dummy <- structure(list(x = 1), class = "dummy")
  expect_false(is_object_list(list(dummy)))
  expect_false(is_object_list(list(x = 1)))

  # valid object lists
  expect_true(is_object_list(list()))
  expect_true(is_object_list(mtcars))
  expect_true(is_object_list(tibble::tibble()))

  expect_true(is_object_list(list(list(x = 1), list(x = 2))))
  expect_true(is_object_list(list(list(x = 1), list(x = "a"))))

  # can handle NULL
  expect_true(is_object_list(list(list(x = 1), NULL)))
})

test_that("detect lists of length 1 (#50)", {
  expect_true(is_object_list(list(list(x = 1, y = 2))))
})

test_that("is_list_of_null() works", {
  expect_true(is_list_of_null(list()))
  expect_true(is_list_of_null(list(NULL)))
  expect_true(is_list_of_null(list(NULL, NULL)))

  expect_false(is_list_of_null(list(NULL, 1)))
})

test_that("list_is_list_of_null() works", {
  expect_true(list_is_list_of_null(list()))
  expect_true(list_is_list_of_null(list(NULL)))
  expect_true(list_is_list_of_null(list(NULL, list())))
  expect_true(list_is_list_of_null(list(list(NULL))))
  expect_false(list_is_list_of_null(list(list(NULL, 1))))
})
