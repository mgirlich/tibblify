test_that("can guess spec for an object", {
  expect_equal(
    guess_spec(list(int = 1L)),
    spec_object(int = tib_int("int"))
  )

  expect_equal(
    guess_spec(list(chr = "a")),
    spec_object(chr = tib_chr("chr"))
  )

  expect_equal(
    guess_spec(list(dtt = new_datetime())),
    spec_object(dtt = tib_scalar("dtt", new_datetime()))
  )

  expect_equal(
    guess_spec(list(int_vec = 1:2)),
    spec_object(int_vec = tib_int_vec("int_vec"))
  )

  expect_equal(
    guess_spec(list(dtt = new_datetime(1:2 + 0))),
    spec_object(dtt = tib_scalar("dtt", new_datetime()))
  )

  expect_equal(
    guess_spec(list(list = list(1, "a"))),
    spec_object(list = tib_list("list"))
  )
})

test_that("can guess spec for object_lists", {
  expect_equal(
    list(
      list(int = 1L, chr_maybe = "a", mixed = 1L, int_vec = 1:2),
      list(int = 2L, mixed = "a")
    ) %>%
      guess_spec(),
    spec_df(
      int = tib_int("int"),
      chr_maybe = tib_chr("chr_maybe", FALSE),
      mixed = tib_list("mixed"),
      int_vec = tib_int_vec("int_vec", FALSE)
    )
  )
})

test_that("can guess spec for data frames", {
  expect_equal(
    guess_spec(
      tibble::tibble(
        lgl = TRUE,
        int = 1L,
        dbl = 1.5,
        chr = "a",
        dtt = vctrs::new_datetime()
      )
    ),
    spec_df(
      lgl = tib_lgl("lgl"),
      int = tib_int("int"),
      dbl = tib_dbl("dbl"),
      chr = tib_chr("chr"),
      dtt = tib_scalar("dtt", ptype = vctrs::new_datetime())
    )
  )

  expect_equal(
    guess_spec(
      tibble::tibble(
        lgl_vec = list(TRUE),
        int_vec = list(1L),
        dbl_vec = list(1.5),
        chr_vec = list("a"),
        dtt_vec = list(vctrs::new_datetime()),
      )
    ),
    spec_df(
      lgl_vec = tib_lgl_vec("lgl_vec"),
      int_vec = tib_int_vec("int_vec"),
      dbl_vec = tib_dbl_vec("dbl_vec"),
      chr_vec = tib_chr_vec("chr_vec"),
      dtt_vec = tib_scalar("dtt_vec", ptype = vctrs::new_datetime())
    )
  )

  expect_equal(
    guess_spec(tibble::tibble(x = list(1, "a"))),
    spec_df(x = tib_list("x"))
  )

  expect_equal(
    guess_spec(tibble::tibble(df = tibble::tibble(int = 1L, chr = "a"))),
    spec_df(
      df = tib_row(
        "df",
        int = tib_int("int"),
        chr = tib_chr("chr")
      )
    )
  )
})

test_that("can guess spec for discog", {
  expect_snapshot(guess_spec(discog) %>% print())
})

test_that("can guess spec for gh_users", {
  expect_snapshot(guess_spec(gh_users) %>% print())
})

test_that("can guess spec for discog", {
  skip("not yet decided")
  # mirror_url -> always `NULL`
  expect_equal(
    tibblify(gh_repos, guess_spec(gh_repos)),
    tibblify(gh_repos),
    ignore_attr = TRUE
  )

  expect_equal(
    tibblify(gh_users, guess_spec(gh_users)),
    tibblify(gh_users),
    ignore_attr = TRUE
  )

  # `got_chars[[19]]$aliases` is an empty list `list()` --> cannot simplify to character
  purrr::map(got_chars, ~ .x["aliases"]) %>% guess_spec
  expect_equal(
    tibblify(got_chars, guess_spec(got_chars)),
    tibblify(got_chars),
    ignore_attr = TRUE
  )

  # default for `list_of<character>` -> character() or NULL?
  expect_equal(
    tibblify(sw_films, guess_spec(sw_films)),
    tibblify(sw_films),
    ignore_attr = TRUE
  )
})
