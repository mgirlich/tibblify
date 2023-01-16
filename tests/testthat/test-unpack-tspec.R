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

test_that("only unpack field in `fields`", {
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

  expect_snapshot({
    (expect_error(unpack_tspec(spec, fields = "not-there")))
    (expect_error(unpack_tspec(spec, fields = c("not-there", "also-not-there"))))
  })

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

test_that("names are repaired", {
  spec <- tspec_df(
    tib_lgl("a"),
    tib_row("x", tib_int("a")),
    tib_row("y", tib_int("b"), tib_row("z", tib_chr("b"))),
  )

  expect_equal(
    unpack_tspec(spec, names_repair = "unique_quiet"),
    tspec_df(
      a...1 = tib_lgl("a"),
      a...2 = tib_int(c("x", "a")),
      b...3 = tib_int(c("y", "b")),
      b...4 = tib_chr(c("y", "z", "b")),
    )
  )

  skip_if(paste0(version$major, ".", version$minor) <= '4.0')
  expect_snapshot({
    # `minimal` isn't supported
    (expect_error(unpack_tspec(spec, names_repair = "minimal")))
    (expect_error(unpack_tspec(spec, names_repair = "check_unique")))
  })
})

test_that("names are cleaned", {
  spec <- tspec_df(
    tib_int("someId"),
    tib_row("aRow", tib_int("subId"))
  )

  expect_equal(
    unpack_tspec(spec, names_sep = "_", names_clean = camel_case_to_snake_case),
    tspec_df(
      some_id = tib_int("someId"),
      a_row_sub_id = tib_int(
        c("aRow", "subId"),
      ),
    )
  )
})
