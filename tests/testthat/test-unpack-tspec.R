test_that("can unpack spec", {
  spec <- tspec_df(
    tib_lgl("a"),
    tib_row("x", tib_int("b"), tib_chr("c"))
  )

  expect_equal(
    unpack_tspec(spec),
    tspec_df(tib_lgl("a"), b = tib_int(c("x", "b")), c = tib_chr(c("x", "c")))
  )


  spec <- tspec_df(
    tib_lgl("a"),
    tib_df("x", tib_row("y", tib_int("b"), tib_chr("c")))
  )

  expect_equal(
    unpack_tspec(spec),
    tspec_df(
      tib_lgl("a"),
      tib_df(
        "x",
        b = tib_int(c("y", "b")),
        c = tib_chr(c("y", "c"))
      )
    )
  )

  spec <- tspec_df(
    tib_lgl("a"),
    tib_recursive("x", tib_int("b"), tib_chr("c"), .children = "children")
  )

  expect_equal(
    unpack_tspec(spec),
    tspec_df(
      tib_lgl("a"),
      tib_df(
        "x",
        b = tib_int(c("y", "b")),
        c = tib_chr(c("y", "c"))
      )
    )
  )
})

test_that("can use names_sep", {
  spec <- tspec_df(
    tib_lgl("a"),
    tib_row("x", tib_int("b"), tib_chr("c"))
  )

  expect_equal(
    unpack_tspec(spec, names_sep = "_"),
    tspec_df(tib_lgl("a"), x_b = tib_int(c("x", "b")), x_c = tib_chr(c("x", "c")))
  )
})

test_that("can recursively unpack", {
  spec <- tspec_df(
    tib_lgl("a"),
    tib_row(
      "x",
      tib_int("b"),
      tib_row("y", tib_chr("c"))
    )
  )

  expect_equal(
    unpack_tspec(spec, recurse = FALSE),
    tspec_df(
      tib_lgl("a"),
      b = tib_int(c("x", "b")),
      y = tib_row(
        c("x", "y"),
        tib_chr("c"),
      ),
    )
  )

  expect_equal(
    unpack_tspec(spec, recurse = TRUE),
    tspec_df(
      tib_lgl("a"),
      b = tib_int(c("x", "b")),
      c = tib_chr(c("x", "y", "c")),
    )
  )
})

test_that("do not unpack if not in `fields`", {
  spec <- tspec_df(
    tib_lgl("a"),
    tib_row("x", tib_int("b")),
    tib_row("y", tib_chr("c")),
  )

  expect_equal(
    unpack_tspec(spec, fields = "x"),
    tspec_df(
      tib_lgl("a"),
      b = tib_int(c("x", "b")),
      y = tib_row("y", tib_chr("c")),
    )
  )

  expect_equal(
    unpack_tspec(spec, fields = "y"),
    tspec_df(
      tib_lgl("a"),
      tib_row("x", tib_int("b")),
      c = tib_chr(c("y", "c")),
    )
  )

  # works together with `recurse`
  spec <- tspec_df(
    tib_lgl("a"),
    tib_row("x", tib_int("b")),
    tib_row("y", tib_row("z", tib_chr("c"))),
  )

  expect_equal(
    unpack_tspec(spec, fields = "y"),
    tspec_df(
      tib_lgl("a"),
      tib_row("x", tib_int("b")),
      c = tib_chr(c("y", "z", "c")),
    )
  )
})

