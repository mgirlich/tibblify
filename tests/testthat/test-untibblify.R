test_that("can untibblify a scalar column", {
  expect_equal(
    untibblify(tibble(x = 1:2)),
    list(list(x = 1), list(x = 2))
  )

  expect_equal(
    untibblify(tibble(x = new_rational(1, 1:2))),
    list(list(x = new_rational(1, 1)), list(x = new_rational(1, 2)))
  )
})

test_that("can untibblify a vector column", {
  expect_equal(
    untibblify(tibble(x = list(NULL, 1:3))),
    list(list(x = NULL), list(x = 1:3))
  )
})

test_that("can untibblify a list column", {
  expect_equal(
    untibblify(tibble(x = list("a", 1))),
    list(list(x = "a"), list(x = 1))
  )

  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  expect_equal(
    untibblify(tibble(x = list(model, 1))),
    list(list(x = model), list(x = 1))
  )
})

test_that("can untibblify a tibble column", {
  x <- tibble(
    x = tibble(
      int = 1:2,
      chr_vec = list("a", NULL),
      df = tibble(chr = c("a", "b"))
    )
  )

  expect_equal(
    untibblify(x),
    list(
      list(x = list(
        int = 1L,
        chr_vec = "a",
        df = list(chr = "a")
      )),
      list(x = list(
        int = 2L,
        chr_vec = NULL,
        df = list(chr = "b")
      ))
    )
  )
})

test_that("can untibblify a list of tibble column", {
  x <- tibble(
    x = list(
      tibble(
        int = 1:2,
        chr_vec = list("a", NULL),
        df = tibble(chr = c("a", "b"))
      ),
      tibble(
        int = 3,
        chr_vec = list("c"),
        df = tibble(chr = NA_character_)
      )
    )
  )

  expect_equal(
    untibblify(x),
    list(
      list(
        x = list(
          list(int = 1L, chr_vec = "a", df = list(chr = "a")),
          list(int = 2L, chr_vec = NULL, df = list(chr = "b"))
        )
      ),
      list(
        x = list(
          list(int = 3L, chr_vec = "c", df = list(chr = NA_character_))
        )
      )
    )
  )
})

test_that("can untibblify object", {
  model <- lm(Sepal.Length ~ Sepal.Width, data = iris)

  expect_equal(
    untibblify(
      list(
        int = 1,
        chr_vec = c("a", "b"),
        model = model,
        df = tibble(x = 1:2, y = c(TRUE, FALSE))
      )
    ),
    list(
      int = 1,
      chr_vec = c("a", "b"),
      model = model,
      df = list(
        list(x = 1, y = TRUE),
        list(x = 2, y = FALSE)
      )
    )
  )
})

test_that("checks input", {
  expect_snapshot({
    (expect_error(untibblify(1:3)))
    (expect_error(untibblify(new_rational(1, 1:3))))
  })
})
